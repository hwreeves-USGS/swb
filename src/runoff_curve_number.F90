!> @file
!> Contains a single module, @ref runoff_curve_number, which estimates runoff by
!> means of the NRCS/SCS curve number method.

!> Updates runoff curve numbers and calculates runoff based on those curve numbers.
module runoff_curve_number
!!****h* SWB/runoff_curve_number
! NAME
!
!   runoff_curve_number.f95 -
!
! SYNOPSIS
!   Initializes and updates SCS curve numbers, and calculates surface runoff
!   from an individual grid cell.
!
! NOTES
!
!!***

  use iso_c_binding, only : c_short, c_int, c_float, c_double
  use types
  use swb_grid

  implicit none

contains

!> @param[inout] pGrd
!! @param[in]    pConfig
!!
!!
!! @f[ E = mc^2 @f]
!!

subroutine runoff_InitializeCurveNumber( pGrd, pConfig )
  !! Looks up the base curve number for each cell and stores it in the grid
  ! [ ARGUMENTS ]
  type ( T_GENERAL_GRID ),pointer :: pGrd        ! pointer to model grid
  type (T_MODEL_CONFIGURATION), pointer :: pConfig ! pointer to data structure that contains
                                                   ! model options, flags, and other setting

  ! [ LOCALS ]
  integer (kind=c_int) :: iCol,iRow,k,l
  type (T_CELL),pointer :: cel              ! pointer to a grid cell data structure
  type ( T_LANDUSE_LOOKUP ),pointer :: pLU  ! pointer to landuse data structure
  logical (kind=c_bool) :: lMatch

  write(UNIT=LU_LOG,FMT=*)"Initializing the base curve numbers"
  ! Initialize all CNs to "bare rock"
  pGrd%Cells(:,:)%rBaseCN = real(5,c_float)

  do iRow=1,pGrd%iNY
    do iCol=1,pGrd%iNX
      ! Use the LU and SG in the grid cell, along with the LU option to
      ! look up the curve number

	  cel => pGrd%Cells(iCol,iRow)

    if (pGrd%iMask(iCol, iRow) == iINACTIVE_CELL) cycle

	  lMatch = lFALSE

      ! iterate through all land use types
      do k = 1,size(pConfig%LU,1)

        !create pointer to a specific land use type
        pLU => pConfig%LU(k)
		    call assert(associated(pLU), &
		   "pointer association failed - runoff_curve_number")

        if ( pLU%iLandUseType == cel%iLandUse ) then

          do l=1,size(pConfig%CN,2)
            if(cel%iSoilGroup==l) then
              cel%rBaseCN = pConfig%CN(k,l)
              lMatch = lTRUE
              exit
            end if

          end do

          if(.not. lMatch) then
            write(UNIT=LU_LOG,FMT=*) iRow,iCol,k, "LU:",pLU%iLandUseType, &
  		        "Soil:",cel%iSoilGroup, "CN:",cel%rBaseCN
            call assert(lFALSE, "Failed to find a curve number for this " &
	  	        //"combined landuse and soil type. See logfile for details.", &
              trim(__FILE__),__LINE__)
          endif

          exit
        end if

      end do

    end do

  end do

  write(UNIT=LU_LOG,FMT=*) 'CN minimum: ',MINVAL(pGrd%Cells(:,:)%rBaseCN)
  write(UNIT=LU_LOG,FMT=*) 'CN maximum: ',MAXVAL(pGrd%Cells(:,:)%rBaseCN)

#ifdef DEBUG_PRINT
  call grid_WriteArcGrid("BASE_CURVE_NUMBER.grd", &
          pGrd%rX0,pGrd%rX1,pGrd%rY0,pGrd%rY1,pGrd%Cells(:,:)%rBaseCN )
#endif

  write(UNIT=LU_LOG,FMT=*) "returning from base curve number initialization..."

  return
end subroutine runoff_InitializeCurveNumber

!--------------------------------------------------------------------------

function prob_runoff_enhancement(rCFGI, rLL, rUL)    result(rPf)

  real (kind=c_float) :: rCFGI, rLL, rUL, rPf

  call Assert(LOGICAL(rLL<=rUL,kind=c_bool), &
    "Lower CFGI limit defining unfrozen ground must be <= upper CFGI limit")

  if(rCFGI <= rLL) then
    rPf = rZERO
  elseif(rCFGI >= rUL) then
    rPf = rONE
  else
    rPf = (rCFGI - rLL) / (rUL - rLL)
  end if

  return

end function prob_runoff_enhancement

!--------------------------------------------------------------------------

subroutine runoff_UpdateCurveNumber(pConfig, cel,iJulDay)
  !! Updates the curve numbers for this iteration
  ! [ ARGUMENTS ]
  type (T_MODEL_CONFIGURATION), pointer :: pConfig ! pointer to data structure that con
                                                   ! model options, flags, and other se
  type (T_CELL),pointer :: cel
  integer (kind=c_int),intent(in) :: iJulDay
  ! [ LOCALS ]
  real (kind=c_float) :: rTotalInflow
  real (kind=c_float) :: rTempCN
  real (kind=c_float) :: rPf

  !! update curve numbers based on antecedent moisture conditions
! real (kind=c_float),dimension(5),parameter :: rDRY_COEFS = (/ &
!                       1.44206581732462E-06_c_float, &
!                      -2.54340415305462E-04_c_float, &
!                       2.07018739405394E-02_c_float, &
!                      -7.67877072822852E-03_c_float, &
!                       2.09678222732103_c_float /)
!  real (kind=c_float),dimension(5),parameter :: rWET_COEFS = (/ &
!                      -6.20352282661163E-07_c_float, &
!                       1.60650096926368E-04_c_float, &
!                      -2.03362629006156E-02_c_float, &
!                       2.01054923513527_c_float, &
!                       3.65427885962651_c_float /)

  ! Here goes...
  rTotalInflow = sum(cel%rNetInflowBuf)

  ! Correct the curve number...
  if(cel%rCFGI>pConfig%rLL_CFGI &
       .and. cel%rSoilWaterCap > rNEAR_ZERO) then
!    cel%rAdjCN = MIN(98_c_float,cel%rAdjCN + &
!       ((98_c_float-cel%rAdjCN) * cel%rSoilMoisture / cel%rSoilWaterCap))

     rPf = prob_runoff_enhancement(cel%rCFGI,pConfig%rLL_CFGI,pConfig%rUL_CFGI)

     ! use probability of runoff enhancement to calculate a weighted
     ! average of curve number under Type II vs Type III antecedent
     ! runoff conditions
     cel%rAdjCN = cel%rBaseCN * (1-rPf) + &
                  (cel%rBaseCN / (0.427 + 0.00573 * cel%rBaseCN) * rPf)

  else if ( if_model_GrowingSeason(pConfig, iJulDay) == iTRUE ) then

    if ( rTotalInflow < pConfig%rDRY_GROWING ) then           ! AMC I


!      cel%rAdjCN = polynomial(cel%rBaseCN,rDRY_COEFS)

!      The following comes from page 192, eq. 3.145 of "SCS Curve Number
!      Methodology"

      cel%rAdjCN = cel%rBaseCN / (2.281 - 0.01281 * cel%rBaseCN)

    else if ( rTotalInflow >= pConfig%rDRY_GROWING &
        .and. rTotalInflow < pConfig%rWET_GROWING ) then	  ! AMC II

       cel%rAdjCN = real(cel%rBaseCN)

    else													  ! AMC III

!      cel%rAdjCN = polynomial(cel%rBaseCN,rWET_COEFS)
      cel%rAdjCN = cel%rBaseCN / (0.427 + 0.00573 * cel%rBaseCN)
    end if

  else ! dormant (non-growing) season

    if ( rTotalInflow < pConfig%rDRY_DORMANT ) then           ! AMC I

!      cel%rAdjCN = polynomial(cel%rBaseCN,rDRY_COEFS)
      cel%rAdjCN = cel%rBaseCN / (2.281 - 0.01281 * cel%rBaseCN)

    else if ( rTotalInflow >= pConfig%rDRY_DORMANT &
        .and. rTotalInflow < pConfig%rWET_DORMANT ) then      ! AMC II

      cel%rAdjCN = real(cel%rBaseCN)

    else													  ! AMC III

!      cel%rAdjCN = polynomial(cel%rBaseCN,rWET_COEFS)
      cel%rAdjCN = cel%rBaseCN / (0.427 + 0.00573 * cel%rBaseCN)

    end if

  end if

  ! ensure that whatever modification have been made to the curve number
  ! remain within reasonable bounds
  cel%rAdjCN = MIN(cel%rAdjCN,rHUNDRED)
  cel%rAdjCN = MAX(cel%rAdjCN,rZERO)

end subroutine runoff_UpdateCurveNumber

!--------------------------------------------------------------------------

function runoff_CellRunoff_CurveNumber(pConfig, cel, iJulDay) result(rOutFlow)
  !! Calculates a single cell's runoff using curve numbers
  type (T_MODEL_CONFIGURATION), pointer :: pConfig ! pointer to data structure that contains
                                                   ! model options, flags, and other settings
  type (T_CELL),pointer :: cel
  integer (kind=c_int),intent(in) :: iJulDay
  ! [ RETURN VALUE ]
  real (kind=c_float) :: rOutFlow
  ! [ LOCALS ]
  real (kind=c_float) :: rP
  real (kind=c_float) :: rCN_05
  real (kind=c_float) :: rSMax

  rP = cel%rNetRainfall &
       + cel%rSnowMelt &
       + cel%rIrrigationAmount &
       + cel%rInFlow

  call runoff_UpdateCurveNumber(pConfig,cel,iJulDay)

  rSMax = (rTHOUSAND / cel%rAdjCN) - rTEN

  if(pConfig%iConfigureInitialAbstraction == &
                                      CONFIG_SM_INIT_ABSTRACTION_TR55) then

    if ( rP > rPOINT2*rSMax ) then
      rOutFlow = ( rP - rPOINT2*rSMax )**2  / (rP + rPOINT8*rSMax)
    else
      rOutFlow = rZERO
    end if

  else if(pConfig%iConfigureInitialAbstraction == &
                                   CONFIG_SM_INIT_ABSTRACTION_HAWKINS) then

    ! Equation 9, Hawkins and others, 2002
    rCN_05 = 100_c_float / &
      ((1.879_c_float * ((100_c_float / cel%rAdjCN) - 1_c_float )**1.15_c_float) +1_c_float)


	  ! Equation 8, Hawkins and others, 2002
    rSMax = 1.33_c_float * ( rSMax ) ** 1.15_c_float

    ! now consider runoff if Ia ~ 0.05S
    if ( rP > 0.05_c_float * rSMax ) then
      rOutFlow = ( rP - 0.05_c_float * rSMax )**2  / (rP + 0.95_c_float*rSMax)
    else
      rOutFlow = rZERO
    end if

  else
    call Assert(lFALSE, "Illegal initial abstraction method specified" )
  end if

  return

end function runoff_CellRunoff_CurveNumber

!--------------------------------------------------------------------------

end module runoff_curve_number
