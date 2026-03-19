module wf_config
  !! Hyperparameter configuration: set and retrieve wandb config values.
  use iso_c_binding, only: c_int, c_double, c_char, c_null_char, c_float
  use wf_c_bindings
  implicit none
  private

  public :: wandb_config_set
  public :: wandb_config_get

  !! Set a wandb config hyperparameter.
  interface wandb_config_set
    module procedure wandb_config_set_integer
    module procedure wandb_config_set_real64
    module procedure wandb_config_set_real32
    module procedure wandb_config_set_string
  end interface wandb_config_set

  !! Read back a config value injected by the sweep agent after wandb_init.
  interface wandb_config_get
    module procedure wandb_config_get_integer
    module procedure wandb_config_get_real64
    module procedure wandb_config_get_real32
    module procedure wandb_config_get_string
  end interface wandb_config_get

contains

  !-----------------------------------------------------------------------------
  ! wandb_config_set  (integer)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_set_integer(key, value)
    character(len=*), intent(in) :: key
    integer,          intent(in) :: value

    call wandb_config_set_int_c(key // c_null_char, int(value, c_int))

  end subroutine wandb_config_set_integer


  !-----------------------------------------------------------------------------
  ! wandb_config_set  (real64)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_set_real64(key, value)
    character(len=*), intent(in) :: key
    real(c_double),   intent(in) :: value

    call wandb_config_set_real_c(key // c_null_char, value)

  end subroutine wandb_config_set_real64


  !-----------------------------------------------------------------------------
  ! wandb_config_set  (real32)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_set_real32(key, value)
    character(len=*), intent(in) :: key
    real(c_float),    intent(in) :: value

    call wandb_config_set_real_c(key // c_null_char, real(value, c_double))

  end subroutine wandb_config_set_real32


  !-----------------------------------------------------------------------------
  ! wandb_config_set  (string)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_set_string(key, value)
    character(len=*), intent(in) :: key
    character(len=*), intent(in) :: value

    call wandb_config_set_str_c( &
         key   // c_null_char, &
         value // c_null_char  &
    )

  end subroutine wandb_config_set_string


  !-----------------------------------------------------------------------------
  ! wandb_config_get  (integer)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_get_integer(key, value, default_value)
    !! Read an integer hyperparameter from the current wandb config.
    !! @param key           Config key.
    !! @param value         Receives the value (or default_value if absent).
    !! @param default_value Fallback when the key is not present.
    character(len=*), intent(in)           :: key
    integer,          intent(out)          :: value
    integer,          intent(in), optional :: default_value

    integer(c_int) :: dflt

    dflt = 0_c_int
    if(present(default_value)) dflt = int(default_value, c_int)
    value = int(wandb_config_get_int_c(key // c_null_char, dflt))

  end subroutine wandb_config_get_integer


  !-----------------------------------------------------------------------------
  ! wandb_config_get  (real64)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_get_real64(key, value, default_value)
    !! Read a double-precision hyperparameter from the current wandb config.
    character(len=*), intent(in)             :: key
    real(c_double),   intent(out)            :: value
    real(c_double),   intent(in),  optional  :: default_value

    real(c_double) :: dflt

    dflt = 0.0_c_double
    if(present(default_value)) dflt = default_value
    value = wandb_config_get_real_c(key // c_null_char, dflt)

  end subroutine wandb_config_get_real64


  !-----------------------------------------------------------------------------
  ! wandb_config_get  (real32)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_get_real32(key, value, default_value)
    !! Read a single-precision hyperparameter from the current wandb config.
    character(len=*), intent(in)            :: key
    real(c_float),    intent(out)           :: value
    real(c_float),    intent(in), optional  :: default_value

    real(c_double) :: dflt, result

    dflt = 0.0_c_double
    if(present(default_value)) dflt = real(default_value, c_double)
    result = wandb_config_get_real_c(key // c_null_char, dflt)
    value  = real(result, c_float)

  end subroutine wandb_config_get_real32


  !-----------------------------------------------------------------------------
  ! wandb_config_get  (string)
  !-----------------------------------------------------------------------------
  subroutine wandb_config_get_string(key, value, default_value)
    !! Read a string hyperparameter from the current wandb config.
    !! The output string value is space-padded to its declared length.
    character(len=*), intent(in)            :: key
    character(len=*), intent(inout)         :: value
    character(len=*), intent(in), optional  :: default_value

    integer :: buf_len, found, i
    character(kind=c_char), allocatable :: buf(:)

    buf_len = len(value) + 1
    allocate(buf(buf_len))
    buf = c_null_char

    found = wandb_config_get_str_c(key // c_null_char, buf, int(buf_len, c_int))

    if(found /= 0)then
       value = ' '
       do i = 1, len(value)
          if(buf(i) == c_null_char) exit
          value(i:i) = buf(i)
       end do
    else if(present(default_value))then
       value = default_value
    end if
    deallocate(buf)

  end subroutine wandb_config_get_string

end module wf_config
