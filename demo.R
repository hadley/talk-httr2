library(httr2)

req <- request("https://api.github.com/")
req_dry_run(req)

resp <- req_perform(req, verbosity = 3)

resp |> resp_content_type()

resp |>
  resp_body_json() |>
  str()

req |> req_dry_run()

req <- request("https://r-project.org")
req |> req_perform(verbosity = 1)
req |> req_perform(verbosity = 2)
req |> req_perform(verbosity = 3)

with_verbosity(req |> req_perform(), verbosity = 1)

# Errors ------------------------------------------------------------------

req <- request("adslkfjdsalkjfadl;kfskd")
resp <- req_perform(req)

req <- request("https://api.github.com/doesntexist")
resp <- req_perform(req)

req <- request("https://api.github.com/user")
resp <- req_perform(req)

last_request()
last_response()
last_response() |> resp_body_json()

# Auth --------------------------------------------------------------------

# Revoke in https://github.com/settings/applications/1636322
# Then clear the cache: rm("7b91122ab057511c0376f115ab9a96dd", envir = httr2:::the$token_cache)

request("https://api.github.com/user") |>
  req_oauth_auth_code(
    client = example_github_client(),
    auth_url = "https://github.com/login/oauth/authorize"
  ) |>
  req_perform() |>
  resp_body_json() |>
  str()

 request("https://api.github.com/user") |>
  req_oauth_device(
    client = example_github_client(),
    auth_url = "https://github.com/login/device/code"
  ) |>
  req_perform() |>
  resp_body_json() |>
  str()

# Show how to create a new app in https://github.com/settings/developers


# Pagination --------------------------------------------------------------

req_auth_github <- function(req) {
  req_oauth_auth_code(
    req,
    client = example_github_client(),
    auth_url = "https://github.com/login/oauth/authorize"
  )
}

# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-a-user

req <- request("https://api.github.com") |>
  req_template("/users/{username}/repos", username = "hadley") |>
  req_auth_github()

resp <- req |> req_perform()

resp |>
  resp_body_json() |>
  View()
resp |> resp_headers()
resp |> resp_header("link")
resp |> resp_link_url("next")


resp2 <- req |>
  req_url(resp |> resp_link_url("next")) |>
  req_perform()
resp2 |> resp_body_json() |> View()

resp2 |> resp_link_url("next")
# Wouldn't it be nice if we could keep going until the end??

resps <- req_perform_iterative(
  req,
  next_req = function(resp, req) {
    req |> req_url(resp |> resp_link_url("next"))
  }
)

# Need to return NULL to indicate that there no pages left to scrape
next_req <- function(resp, req) {
  next_url <- resp |> resp_link_url("next")
  if (is.null(next_url)) {
    return(NULL)
  }
  req |> req_url(next_url)
}

resps <- req_perform_iterative(req, next_req, max_reqs = Inf)
length(resps)
resps[[1]] |> resp_body_json() |> View()
resps[[2]] |> resp_body_json() |> View()
data <- resps_data(resps, resp_body_json)
data |> View()

library(tidyverse)
tibble(json = data) |>
  unnest_wider(json)
