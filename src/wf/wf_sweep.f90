module wf_sweep
  !! Sweep management: configuration builder, sweep registration, and agents.
  use iso_c_binding, only: c_int, c_double, c_char, c_null_char, c_float
  use wf_c_bindings
  implicit none
  private

  public :: wandb_sweep_config_type
  public :: wandb_sweep
  public :: wandb_agent
  public :: wandb_sweep_start_agent
  public :: wandb_sweep_next_params
  public :: wandb_sweep_run_done


  !-----------------------------------------------------------------------------
  ! wandb_sweep_config_type — programmatic sweep configuration builder
  !-----------------------------------------------------------------------------
  !! Builder for a wandb sweep configuration.
  !!
  !! Build the configuration with the type-bound procedures, then pass
  !! it directly to wandb_sweep or call to_json() for the raw string.
  !!
  !! ## Example
  !!
  !! ```fortran
  !! type(wandb_sweep_config_type) :: cfg
  !!
  !! call cfg%set_method("bayes")
  !! call cfg%set_metric("val_loss", "minimize")
  !!
  !! call cfg%add_param_range("learning_rate", 1e-5_real64, 1e-2_real64, &
  !!                           distribution="log_uniform_values")
  !! call cfg%add_param_values("hidden_size", [32, 64, 128, 256])
  !! call cfg%add_param_values("activation", ["relu   ", "tanh   ", "sigmoid"])
  !!
  !! call wandb_sweep(cfg, project="my-project", sweep_id=id)
  !! ```
  type :: wandb_sweep_config_type
    character(len=:), allocatable :: method_str
    character(len=:), allocatable :: metric_name_str
    character(len=:), allocatable :: metric_goal_str
    character(len=:), allocatable :: params_buf  ! accumulated parameter JSON
    integer :: num_params = 0
  contains
    procedure :: set_method        => swcfg_set_method
    procedure :: set_metric        => swcfg_set_metric
    procedure, private :: add_range_r32   => swcfg_add_range_r32
    procedure, private :: add_range_r64   => swcfg_add_range_r64
    procedure, private :: add_vals_int    => swcfg_add_values_int
    procedure, private :: add_vals_r32    => swcfg_add_values_r32
    procedure, private :: add_vals_r64    => swcfg_add_values_r64
    procedure, private :: add_vals_str    => swcfg_add_values_str
    generic :: add_param_range  => add_range_r32, add_range_r64
    generic :: add_param_values => add_vals_int, add_vals_r32, &
                                    add_vals_r64, add_vals_str
    procedure :: to_json => swcfg_to_json
  end type wandb_sweep_config_type


  !! Register a sweep — accepts either a raw JSON string or a
  !! wandb_sweep_config_type built with the helper API.
  interface wandb_sweep
    module procedure wandb_sweep_json_str
    module procedure wandb_sweep_cfg_obj
  end interface wandb_sweep

contains

  !-----------------------------------------------------------------------------
  ! wandb_sweep  (raw JSON string variant)
  !-----------------------------------------------------------------------------
  subroutine wandb_sweep_json_str(config_json, project, sweep_id, entity)
    !! Register a hyperparameter sweep with wandb.
    !!
    !! @param config_json  JSON string describing the sweep (method, metric,
    !!                     parameters).
    !! @param project      wandb project name.
    !! @param sweep_id     Output: the sweep ID string assigned by wandb.
    !! @param entity       Optional wandb entity/team.
    character(len=*),           intent(in)  :: config_json
    character(len=*),           intent(in)  :: project
    character(len=*),           intent(out) :: sweep_id
    character(len=*), optional, intent(in)  :: entity

    integer, parameter :: BUF_LEN = 256
    character(kind=c_char) :: id_buf(BUF_LEN)
    character(len=:), allocatable :: c_entity
    integer(c_int) :: rc
    integer :: i

    if(present(entity))then
       c_entity = entity // c_null_char
    else
       c_entity = c_null_char
    end if

    id_buf = c_null_char
    rc = wandb_sweep_c( &
         config_json // c_null_char, &
         project     // c_null_char, &
         c_entity,                   &
         id_buf,                     &
         int(BUF_LEN, c_int)         &
    )

    if(rc /= 0)then
       write(0,*) "[wf__wandb] WARNING: wandb_sweep failed (rc=", rc, ")"
       sweep_id = ' '
       return
    end if

    sweep_id = ' '
    do i = 1, len(sweep_id)
       if(id_buf(i) == c_null_char) exit
       sweep_id(i:i) = id_buf(i)
    end do

  end subroutine wandb_sweep_json_str


  !-----------------------------------------------------------------------------
  ! wandb_sweep  (config-type variant)
  !-----------------------------------------------------------------------------
  subroutine wandb_sweep_cfg_obj(config, project, sweep_id, entity)
    !! Register a sweep from a wandb_sweep_config_type builder object.
    type(wandb_sweep_config_type), intent(in)  :: config
    character(len=*),              intent(in)  :: project
    character(len=*),              intent(out) :: sweep_id
    character(len=*), optional,    intent(in)  :: entity

    character(len=:), allocatable :: json

    json = config%to_json()
    if(present(entity))then
       call wandb_sweep_json_str(json, project, sweep_id, entity)
    else
       call wandb_sweep_json_str(json, project, sweep_id)
    end if

  end subroutine wandb_sweep_cfg_obj


  !-----------------------------------------------------------------------------
  ! wandb_agent
  !-----------------------------------------------------------------------------
  subroutine wandb_agent(sweep_id, project, count, entity)
    !! Run a wandb sweep agent.
    !!
    !! Calls wandb.agent(sweep_id, count=count, project=project).  After this
    !! returns, call wandb_config_get to read the sampled hyperparameters,
    !! run your training loop, then call wandb_finish.
    !!
    !! @param sweep_id  Sweep ID returned by wandb_sweep.
    !! @param project   wandb project name.
    !! @param count     Number of runs to execute (0 = until sweep is done).
    !! @param entity    Optional wandb entity/team.
    character(len=*),           intent(in) :: sweep_id
    character(len=*),           intent(in) :: project
    integer,          optional, intent(in) :: count
    character(len=*), optional, intent(in) :: entity

    character(len=:), allocatable :: c_entity
    integer(c_int) :: rc, c_count

    c_count = 0_c_int
    if(present(count)) c_count = int(count, c_int)

    if(present(entity))then
       c_entity = entity // c_null_char
    else
       c_entity = c_null_char
    end if

    rc = wandb_agent_c( &
         sweep_id // c_null_char, &
         project  // c_null_char, &
         c_entity,                &
         c_count                  &
    )

    if(rc /= 0)then
       write(0,*) "[wf__wandb] WARNING: wandb_agent failed (rc=", rc, ")"
    end if

  end subroutine wandb_agent


  !-----------------------------------------------------------------------------
  ! wandb_sweep_start_agent
  !-----------------------------------------------------------------------------
  subroutine wandb_sweep_start_agent(sweep_id, project, count, entity)
    !! Start a wandb sweep agent in a background Python thread.
    !!
    !! ## Usage pattern
    !!
    !! ```fortran
    !! call wandb_sweep(config=cfg, project="my-proj", sweep_id=sid)
    !! call wandb_sweep_start_agent(sid, "my-proj", count=5)
    !! do i = 1, 5
    !!    call wandb_sweep_next_params(params_json)
    !!    ! parse params_json, train, log ...
    !!    call wandb_sweep_run_done()
    !! end do
    !! call wandb_shutdown()
    !! ```
    character(len=*),           intent(in) :: sweep_id
    character(len=*),           intent(in) :: project
    integer,                    intent(in) :: count
    character(len=*), optional, intent(in) :: entity

    character(len=:), allocatable :: c_entity
    integer(c_int) :: rc

    if(present(entity))then
       c_entity = trim(entity) // c_null_char
    else
       c_entity = c_null_char
    end if

    rc = wandb_sweep_start_agent_c( &
         trim(sweep_id) // c_null_char, &
         trim(project)  // c_null_char, &
         c_entity,                       &
         int(count, c_int)               &
    )

    if(rc /= 0)then
       write(0,*) "[wf__wandb] WARNING: wandb_sweep_start_agent failed (rc=", rc, ")"
    end if

  end subroutine wandb_sweep_start_agent


  !-----------------------------------------------------------------------------
  ! wandb_sweep_next_params
  !-----------------------------------------------------------------------------
  subroutine wandb_sweep_next_params(params_json, timeout_s)
    !! Block until the sweep agent has started the next run and populated
    !! wandb.config with the sweep-sampled hyperparameters.
    !!
    !! @param params_json  Receives the sampled hyperparameters as a JSON
    !!                     object string, e.g. {"lr":0.01,"hidden":32}.
    !! @param timeout_s    Seconds to wait before giving up (default: 120.0).
    character(len=*),          intent(out) :: params_json
    real(c_double), optional,  intent(in)  :: timeout_s

    character(kind=c_char), dimension(4096) :: c_buf
    real(c_double) :: tval
    integer(c_int) :: ok
    integer :: i

    tval = 120.0_c_double
    if(present(timeout_s)) tval = timeout_s

    ok = wandb_sweep_params_c(c_buf, int(4096, c_int), tval)

    if(ok == 0_c_int)then
       write(0,*) "[wf__wandb] WARNING: wandb_sweep_next_params timed out."
       params_json = '{}'
       return
    end if

    params_json = ' '
    do i = 1, len(params_json)
       if(c_buf(i) == c_null_char) exit
       params_json(i:i) = c_buf(i)
    end do

  end subroutine wandb_sweep_next_params


  !-----------------------------------------------------------------------------
  ! wandb_sweep_run_done
  !-----------------------------------------------------------------------------
  subroutine wandb_sweep_run_done()
    !! Signal that the current sweep run's training is finished.
    !!
    !! The sweep agent callback will call wandb.finish() and request the next
    !! set of hyperparameters from the sweep controller.
    !! Call this once per sweep run, after all logging is done.
    call wandb_sweep_run_done_c()
  end subroutine wandb_sweep_run_done


  !=============================================================================
  ! wandb_sweep_config_type — type-bound procedure implementations
  !=============================================================================

  subroutine swcfg_set_method(self, method)
    !! Set the sweep search method: "bayes" | "grid" | "random".
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: method

    self%method_str = trim(method)

  end subroutine swcfg_set_method


  subroutine swcfg_set_metric(self, name, goal)
    !! Set the optimisation metric.
    !! @param name  Metric key logged via wandb_log (e.g. "val_loss").
    !! @param goal  "minimize" or "maximize".
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    character(len=*),               intent(in)    :: goal

    self%metric_name_str = trim(name)
    self%metric_goal_str = trim(goal)

  end subroutine swcfg_set_metric


  !---------------------------------------------------------------------------
  ! add_param_range  (real32 / real64)
  !---------------------------------------------------------------------------
  subroutine swcfg_add_range_r32(self, name, min_val, max_val, distribution)
    !! Add a continuous hyperparameter with min/max bounds (single precision).
    !! @param distribution  wandb distribution string (default "uniform").
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    real(c_float),                  intent(in)    :: min_val, max_val
    character(len=*), optional,     intent(in)    :: distribution

    call swcfg_add_range_r64(self, name, &
         real(min_val, c_double), real(max_val, c_double), distribution)

  end subroutine swcfg_add_range_r32


  subroutine swcfg_add_range_r64(self, name, min_val, max_val, distribution)
    !! Add a continuous hyperparameter with min/max bounds (double precision).
    !! @param distribution  wandb distribution string (default "uniform").
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    real(c_double),                 intent(in)    :: min_val, max_val
    character(len=*), optional,     intent(in)    :: distribution

    character(len=:), allocatable :: distrib, fragment

    if(present(distribution))then
       distrib = trim(distribution)
    else
       distrib = "uniform"
    end if

    fragment = '"' // trim(name) // '":{' // &
               '"distribution":"' // distrib // '",' // &
               '"min":' // r64_to_json(min_val) // ',' // &
               '"max":' // r64_to_json(max_val) // '}'

    if(.not. allocated(self%params_buf)) self%params_buf = ''
    if(self%num_params > 0)then
       self%params_buf = self%params_buf // ',' // fragment
    else
       self%params_buf = self%params_buf // fragment
    end if
    self%num_params = self%num_params + 1

  end subroutine swcfg_add_range_r64


  !---------------------------------------------------------------------------
  ! add_param_values  (integer array)
  !---------------------------------------------------------------------------
  subroutine swcfg_add_values_int(self, name, values)
    !! Add a discrete integer hyperparameter.
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    integer,                        intent(in)    :: values(:)

    character(len=:), allocatable :: arr, fragment
    character(len=32) :: buf
    integer :: i

    arr = '['
    do i = 1, size(values)
       write(buf, '(i0)') values(i)
       if(i > 1) arr = arr // ','
       arr = arr // trim(buf)
    end do
    arr = arr // ']'

    fragment = '"' // trim(name) // '":{"values":' // arr // '}'
    if(.not. allocated(self%params_buf)) self%params_buf = ''
    if(self%num_params > 0)then
       self%params_buf = self%params_buf // ',' // fragment
    else
       self%params_buf = self%params_buf // fragment
    end if
    self%num_params = self%num_params + 1

  end subroutine swcfg_add_values_int


  !---------------------------------------------------------------------------
  ! add_param_values  (real32 array)
  !---------------------------------------------------------------------------
  subroutine swcfg_add_values_r32(self, name, values)
    !! Add a discrete real-valued hyperparameter (single precision).
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    real(c_float),                  intent(in)    :: values(:)

    real(c_double), allocatable :: tmp(:)
    integer :: i

    allocate(tmp(size(values)))
    do i = 1, size(values)
       tmp(i) = real(values(i), c_double)
    end do
    call swcfg_add_values_r64(self, name, tmp)

  end subroutine swcfg_add_values_r32


  !---------------------------------------------------------------------------
  ! add_param_values  (real64 array)
  !---------------------------------------------------------------------------
  subroutine swcfg_add_values_r64(self, name, values)
    !! Add a discrete real-valued hyperparameter (double precision).
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    real(c_double),                 intent(in)    :: values(:)

    character(len=:), allocatable :: arr, fragment
    integer :: i

    arr = '['
    do i = 1, size(values)
       if(i > 1) arr = arr // ','
       arr = arr // r64_to_json(values(i))
    end do
    arr = arr // ']'

    fragment = '"' // trim(name) // '":{"values":' // arr // '}'
    if(.not. allocated(self%params_buf)) self%params_buf = ''
    if(self%num_params > 0)then
       self%params_buf = self%params_buf // ',' // fragment
    else
       self%params_buf = self%params_buf // fragment
    end if
    self%num_params = self%num_params + 1

  end subroutine swcfg_add_values_r64


  !---------------------------------------------------------------------------
  ! add_param_values  (string array)
  !---------------------------------------------------------------------------
  subroutine swcfg_add_values_str(self, name, values)
    !! Add a discrete string hyperparameter.
    !! All elements of values must have the same declared length; trailing
    !! spaces are trimmed automatically.
    class(wandb_sweep_config_type), intent(inout) :: self
    character(len=*),               intent(in)    :: name
    character(len=*),               intent(in)    :: values(:)

    character(len=:), allocatable :: arr, fragment
    integer :: i

    arr = '['
    do i = 1, size(values)
       if(i > 1) arr = arr // ','
       arr = arr // '"' // trim(values(i)) // '"'
    end do
    arr = arr // ']'

    fragment = '"' // trim(name) // '":{"values":' // arr // '}'
    if(.not. allocated(self%params_buf)) self%params_buf = ''
    if(self%num_params > 0)then
       self%params_buf = self%params_buf // ',' // fragment
    else
       self%params_buf = self%params_buf // fragment
    end if
    self%num_params = self%num_params + 1

  end subroutine swcfg_add_values_str


  !---------------------------------------------------------------------------
  ! to_json
  !---------------------------------------------------------------------------
  function swcfg_to_json(self) result(json)
    !! Serialise the configuration to a JSON string suitable for wandb_sweep.
    class(wandb_sweep_config_type), intent(in) :: self
    character(len=:), allocatable :: json

    character(len=:), allocatable :: method, metric_part, params_part

    if(allocated(self%method_str))then
       method = self%method_str
    else
       method = 'bayes'
    end if

    if(allocated(self%metric_name_str))then
       metric_part = ',"metric":{"name":"' // self%metric_name_str // &
                     '","goal":"'           // self%metric_goal_str // '"}'
    else
       metric_part = ''
    end if

    if(allocated(self%params_buf) .and. len(self%params_buf) > 0)then
       params_part = ',"parameters":{' // self%params_buf // '}'
    else
       params_part = ',"parameters":{}'
    end if

    json = '{"method":"' // trim(method) // '"' // &
            metric_part // params_part // '}'

  end function swcfg_to_json


  !---------------------------------------------------------------------------
  ! Private helper: format a real64 as a compact JSON number string.
  !---------------------------------------------------------------------------
  function r64_to_json(x) result(s)
    real(c_double), intent(in) :: x
    character(len=32) :: s
    integer :: i

    write(s, '(ES23.8E3)') x
    s = adjustl(s)
    do i = 1, len_trim(s)
       if(s(i:i) == 'E') s(i:i) = 'e'
    end do
    s = trim(s)

  end function r64_to_json

end module wf_sweep
