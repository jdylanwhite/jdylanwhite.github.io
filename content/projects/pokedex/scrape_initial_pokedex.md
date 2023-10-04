
# Table of Contents

1.  [Load Libraries](#org6692a17)
2.  [Load National Pokedex Page](#orgf636f73)
3.  [Get the Initial Pokedex Data](#org62fbce4)
4.  [Assemble Initial Pokedex Dataframe](#org5caf5c3)

Before we scrape all of the Pokemon data, let&rsquo;s start by building the table of just Pokemon and their number, again using the [PokemonDB](https://pokemondb.net/) site.


<a id="org6692a17"></a>

# Load Libraries

Again, we&rsquo;ll primarily use the `rvest` package, along with `dplyr` and `tidyr` for some additional common functions.

    
    # Load packages
    library(rvest)
    library(dplyr)
    library(tidyr)


<a id="orgf636f73"></a>

# Load National Pokedex Page

Let&rsquo;s load the page data from the [National Pokedex](https://pokemondb.net/pokedex/national) page, which has a table of all Pokemon, their number, and a link to their page.

    
    # Set the URL to fetch data from
    url <- "https://pokemondb.net/pokedex/national"
    
    # Read the body from the page
    body <- url nil>nil read_html() nil>nil html_nodes("body")
    
    # Get the info cards for each Pokemon
    infocards <- html_nodes(body, "span.infocard-lg-data.text-muted")


<a id="org62fbce4"></a>

# Get the Initial Pokedex Data

Using the tags for each &ldquo;infocard&rdquo; which contains the information we want for each Pokemon, get the numbers, names, and URLs for each Pokemon.

    
    # Fetch the Pokemon numbers
    numbers <- infocards nil>nil
      html_element("small") nil>nil
      html_text()
    
    # Fetch the Pokemon names
    names <- infocards nil>nil
      html_element("a") nil>nil
      html_text()
    
    # Fetch the Pokemon URLs
    urls <- infocards nil>nil
      html_element("a") nil>nil
      html_attr("href")
    urls <- paste0("https://pokemondb.net", urls)


<a id="org5caf5c3"></a>

# Assemble Initial Pokedex Dataframe

Finally, let&rsquo;s put all of this data into a dataframe.

    
    # Create tibble for Pokedex
    data_tbl <- tibble(numbers, names, urls) nil>nil
      rename(Number = numbers, Name = names, URLs = urls)
    data_tbl$Number <- substring(data_tbl$Number, 2) nil>nil as.numeric()
    
    glimpse(data_tbl)

This initial table will serve as the initial table for scraping *all* of the Pokemon data.

