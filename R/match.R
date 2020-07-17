#' Match input place with a geographical zone
#'
#' This function is used to match the input `place` with the URL of the
#' corresponding pbf file (and its file size, if present).
#'
#' @inheritParams oe_get
#' @param ... arguments passed to other methods
#'
#' @return A list with two elements, named `url` and `file_size`. The first
#'   element is the URL of the file associated with the input `place`, while
#'   the second element is the size of the file (which may be `NULL` or `NA`)
#' @export
#'
#' @seealso `oe_check_pattern()`
#'
#' @examples
#' # The simplest example:
#' oe_match("Italy")
#'
#' # Don't run example, see issue #49
#' # Match the input zone using an sfc_POINT object:
#' milan_duomo = sf::st_sfc(sf::st_point(c(1514924, 5034552)), crs = 3003)
#' oe_match(milan_duomo)
#'
#' # Match the input zone using a numeric vector of coordinates
#' # (in which case crs = 4326 is assumed)
#' oe_match(c(9.1916, 45.4650)) # Milan, Duomo using CRS = 4326
#'
#' # Perform the matching operations using other columns instead of "name".
#' oe_match("RU", match_by = "iso3166_1_alpha2")
#' # Increase the max_string_dist parameter and help the function:
#' oe_match("Isle Wight", max_string_dist = 3)
#' # but be aware that it can be dangerous:
#' oe_match("London", max_string_dist = 3, oe_verbose = TRUE)
#'
#' # Check interactive_ask:
#' if (interactive()) {
#'     oe_match("London", interactive_ask = TRUE)
#' }
#'
#' # Change the provider:
#' oe_match("Leeds", provider = "bbbike")
oe_match = function(place, ...) {
  UseMethod("oe_match")
}

#' @rdname oe_match
#' @export
oe_match.default = function(place, ...) {
  stop(
    "At the moment there is no support for matching objects of class ",
    class(place)[1], ".",
    " Feel free to open a new issue at github.com/itsleeds/osmextractr", call. = FALSE
  )
}

#' @inheritParams oe_get
#' @rdname oe_match
#' @export
oe_match.sfc_POINT = function(
  place,
  provider = "geofabrik",
  oe_verbose = FALSE,
  ...
) {
  # For the moment we support only length-one sfc_POINT objects
  if (length(place) > 1L) {
    stop(
      "At the moment we support only length-one sfc_POINT objects for 'place' parameter.",
      " Feel free to open a new issue at github.com/itsleeds/osmextractr",
      call. = FALSE
    )
  }

  # Load the data associated with the chosen provider.
  provider_data = load_provider_data(provider)

  # Check the CRS
  if (sf::st_crs(place) != sf::st_crs(provider_data)) {
    place = sf::st_transform(place, crs = sf::st_crs(provider_data))
  }

  # Spatial subset according to sf::st_intersects (maybe add a parameter for that)
  matched_zones = provider_data[place, ]

  # Check that the input zone intersects at least 1 area
  if (nrow(matched_zones) == 0L) {
    stop("The input place does not intersect any area for the chosen provider.")
  }

  # What to do if there are multiple matches?  (maybe add a parameter for that)
  if (nrow(matched_zones) > 1L) {
    # Check for the "smallest" zone
    smallest_zone = matched_zones[which.max(matched_zones[["level"]]), ]
  }

  # Return a list with the URL and the file_size of the matched place
  result = list(
    url = smallest_zone[["pbf"]],
    file_size = smallest_zone[["pbf_file_size"]]
  )
  result

}

#' @inheritParams oe_get
#' @rdname oe_match
#' @export
oe_match.numeric = function(
  place,
  provider = "geofabrik",
  oe_verbose = FALSE,
  ...
) {
  # In this case I just need to build the appropriate object and create a
  # wrapper around oe_match.sfc_POINT
  if (length(place) != 2L) {
    stop(
      "You need to provide a pair of coordinates and you passed as input",
      " a vector of length ", length(place)
    )
  }

  # Build the sfc_POINT object
  place = sf::st_sfc(sf::st_point(place), crs = 4326)

  oe_match(place, provider = provider, oe_verbose = oe_verbose, ...)
}

#' @inheritParams oe_get
#' @rdname oe_match
#' @export
oe_match.character = function(
  place,
  provider = "geofabrik",
  match_by = "name",
  max_string_dist = 1,
  interactive_ask = FALSE,
  oe_verbose = FALSE,
  ...
  ) {
  # For the moment we support only length-one character vectors
  if (length(place) > 1L) {
    stop(
      "At the moment we support only length-one character vectors for 'place' parameter.",
      " Feel free to open a new issue at ...",
      call. = FALSE
    )
  }

  # Load the data associated with the chosen provider.
  provider_data = load_provider_data(provider)

  # Check that the value of match_by argument corresponds to one of the columns
  # in provider_data
  if (match_by %!in% colnames(provider_data)) {
    stop(
      "You cannot set match_by = ", match_by,
      " since it's not one of the columns of the provider dataframe",
      call. = FALSE
    )
  }

  # If the user is looking for a match using iso3166_1_alpha2 or iso3166_2 codes
  # then max_string_dist should be 0
  if (match_by %in% c("iso3166_1_alpha2", "iso3166_2") & max_string_dist > 0) {
    max_string_dist = 0
  }

  # Look for the best match between the input 'place' and the data column
  # selected with the match_by argument.
  matching_dists = utils::adist(provider_data[[match_by]], place, ignore.case = TRUE)
  best_match_id = which.min(matching_dists)
  # WHAT TO DO IF THERE ARE MULTIPLE BEST MATCHES?
  best_matched_place = provider_data[best_match_id, ]

  # Check if the best match is still too far
  high_distance = matching_dists[best_match_id, 1] > max_string_dist

  if (isTRUE(high_distance)) {
    if (isTRUE(oe_verbose) || isTRUE(interactive_ask)) {
      message(
        "No exact matching found for place = ", place, ". ",
        "Best match is ", best_matched_place[[match_by]], "."
      )
    }
    if (interactive() && isTRUE(interactive_ask)) {
      continue = utils::menu(
        choices = c("Yes", "No"),
        title = "Do you confirm that this is the right match?"
      )
      # since the options are Yes/No, then Yes == 1L
      if (continue != 1L) {
        stop("Search for a closer match in the chosen provider's database.",
             call. = FALSE
        )
      }
    } else {
      stop(
        "String distance between best match and the input place is ",
        matching_dists[best_match_id, 1],
        ", while the maximum threshold distance is equal to ",
        max_string_dist,
        ". You should increase the max_string_dist parameter, ",
        "look for a closer match in the chosen provider database",
        " or consider using a different match_by variable.", call. = FALSE
      )
    }
  }

  if (isTRUE(oe_verbose)) {
    message("The input place was matched with: ", best_matched_place[[match_by]])
  }

  result = list(
    url = best_matched_place[["pbf"]],
    file_size = best_matched_place[["pbf_file_size"]]
  )
  result
}

# The following function is used just to load the correct provider database
load_provider_data = function(provider) {
  if (provider %!in% oe_available_providers()) {
    stop(
      "You can only select one of the following providers: ",
      oe_available_providers(),
      call. = FALSE
    )
  }

  provider_data = switch(
    provider,
    "geofabrik" = geofabrik_zones,
    "test" = test_zones,
    "bbbike" = bbbike_zones
    # , "another" = another_provider
  )
  sf::st_crs(provider_data) = 4326
  provider_data
}

oe_available_providers = function() {
  c(
    "geofabrik",
    "test",
    "bbbike"
  )
}

#' Check for patterns in the provider's data columns
#'
#' This function is used to explore the provider's data and check for patterns
#' in the existing columns
#'
#' @param pattern Character string for the pattern that should be matched
#' @inheritParams oe_get
#' @param match_by Column name in the provider dataset used to find the match,
#' `name` by default.
#' @param full_row Return all columns in the matching row?
#' `FALSE` by default.
#'
#' @return A
#' @export
#'
#' @examples
#' oe_check_pattern(
#'   pattern = "Yorkshire",
#'   provider = "geofabrik",
#'   match_by = "name"
#' )
#' res = oe_check_pattern(
#'   pattern = "Yorkshire",
#'   provider = "geofabrik",
#'   match_by = "name",
#'   full_row = TRUE
#' )
#' sf::st_drop_geometry(res)[1:3]
oe_check_pattern = function(
  pattern,
  provider = "geofabrik",
  match_by = "name",
  full_row = FALSE
) {
  # Check that the input pattern is a character vector
  if (!is.character(pattern)) {
    pattern = structure( # taken from base::grep
      as.character(pattern),
      names = names(pattern)
    )
  }
  # Load the dataset associated with the chosen provider
  provider_data = load_provider_data(provider)

  # Check that the value of match_by argument corresponds to one of the columns
  # in provider_data
  if (match_by %!in% colnames(provider_data)) {
    stop(
      "You cannot set match_by = ", match_by,
      " since it's not one of the columns of the provider dataframe",
      call. = FALSE
    )
  }

  # Extract the appropriate vector
  match_by_column = provider_data[[match_by]]

  # Then we extract only the elements of the match_by_column that match the
  # input pattern.
  match_ID = grep(pattern, match_by_column)

  # If full_row is TRUE than return the corresponding row of provider_data,
  # otherwise just the matched pattern.
  if (isTRUE(full_row)) {
    provider_data[match_ID, ]
  } else {
    match_by_column[match_ID]
  }
}
