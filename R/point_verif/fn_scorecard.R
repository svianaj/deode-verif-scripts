# Function to calculate the scorecards

scorecard_function <- function(
  param,
  start_date,
  end_date,
  by,
  fcst_model,
  fcst_type='det',
  fcst_path,
  obs_path,
  n,
  pooled_by,
  min_cases,
  stations,
  groupings = "lead_time"
) {

  # Output some information to the user
  message("\n")
  message("Generating scorecard data for ", param)
  message("==============================", rep("=", nchar(param)), "\n")

  fcst <- read_point_forecast(
    dttm=seq_dttm(start_date,end_date,by),
    fcst_model = fcst_model,
    fcst_type  = fcst_type,
    parameter  = param,
    stations   = stations,
    file_path  = fcst_path
  )

  fcst <- common_cases(fcst)

  stations <- pull_stations(fcst)

  obs <- read_point_obs(
    dttm=unique_valid_dttm(fcst),
    parameter  = param,
    obs_path   = obs_path,
    stations   = stations,
    gross_error_check = FALSE
  )
  
  # If no obervations were found return NULL
  if (nrow(obs) < 1) return(NULL)
  #This does an inner join of fcst and obs, so that only cases with matching f/o are retained
  fcst <- join_to_fcst(fcst, obs)
  fcst <- check_obs_against_fcst(fcst, {{param}})
  
 # verif_s10m <- det_verify(s10m, S10m, thresholds = seq(2.5, 12.5, 2.5))
  if (fcst_type == "det") {
    cat("Using det forecast option in scorecard_function \n")
    bootstrap_verify(
       fcst,
       det_verify,
       {{param}},
       n=n,
       min_cases = min_cases,
       pool_by = pooled_by,
       groupings = groupings)
       #parallel=TRUE)
  } else {
    cat("Using not det forecast option in scorecard_function \n")
    pooled_bootstrap_score(
      fcst,
      ens_verify,
      {{param}},
      n         = n,
      pooled_by = pooled_by,
      min_cases = min_cases,
      groupings = groupings
    )
  }

}


