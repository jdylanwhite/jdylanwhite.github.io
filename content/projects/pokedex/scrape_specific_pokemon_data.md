
# Table of Contents

1.  [Load Packages](#org4c37515)
2.  [Specify Parameters](#orga836263)
3.  [Get Tables From Page](#orgcc9cb3a)
4.  [Getting Stats From the Table](#org2b171a8)
5.  [Clean Up Scraped Data](#org0c2c6b3)
6.  [Add Evolution Data](#org35e84a3)

On each Pokemon&rsquo;s page (for example, [Gengar&rsquo;s page](https://pokemondb.net/pokedex/gengar)), there&rsquo;s a consistent and structured data that we can programmatically scrape. Each page has a table showing the Pokemon&rsquo;s &ldquo;national number&rdquo;, type(s), height, and weight, another table showing base stats for battle such as health points (HP), attack, and defense, and several other tables and information.

To scrape the data using R, I&rsquo;ll rely on the `rvest` package to extract data from different parts of the site. Looking at the site&rsquo;s source HTML is a helpful part of this process in knowing what to extract.


<a id="org4c37515"></a>

# Load Packages

Let&rsquo;s start by loading all of the packages we&rsquo;ll need.

    
    # Load packages
    library(rvest)
    library(dplyr)
    library(tidyr)
    library(tibble)


<a id="orga836263"></a>

# Specify Parameters

Next, we&rsquo;ll specify the Pokemon we want to look up and the URL from which to scrape. Let&rsquo;s stick with Gengar for now.

    
    # Set the name of the Pokemon
    name <- "Gengar"
    
    # Convert name to lower case for the URL
    name <- tolower(name)
    
    # Build the URL to fetch Pokemon data
    url <- paste0("https://pokemondb.net/pokedex/", name)


<a id="orgcc9cb3a"></a>

# Get Tables From Page

Now that we&rsquo;ve got the URL to scrape, we need to fetch the tables storing the Pokemon&rsquo;s data we want to scrape.

    
    # Read the body from the page
    body <- url nil>nil read_html() nil>nil html_nodes("body")
    
    # Get the tables with the vital information
    vitals_tables <- html_nodes(body, "table.vitals-table")
    main_table <- html_table(vitals_tables[1])[[1]]
    stats_table <- html_table(vitals_tables[4])[[1]]
    
    glimpse(main_table)

This gives a pretty messy table, but it&rsquo;s definitely something we can use.


<a id="org2b171a8"></a>

# Getting Stats From the Table

Ultimately, we&rsquo;re going to want to pull all of this data into one structured table, so let&rsquo;s accumulate all of this data into one row. We&rsquo;ll need to tweak the table to make it easier to extract data from, then we&rsquo;ll put together the Pokemon information and base battle stats.

    
    # Function to help us turn the first row of our tibble into the header
    header_from_row <- function(df) {
      names(df) <- as.character(unlist(df[1, ]))
      df[-1, ]
    }
    
    # Get the types, species, height, and weight from the table
    main_tbl <- main_table nil>nil
      t nil>nil
      as_tibble nil>nil
      header_from_row nil>nil
      select(c("Type", "Species", "Height", "Weight"))
    
    # Get stats columns
    stats_tbl <- stats_table nil>nil
      select(c("X1", "X2")) nil>nil
      t nil>nil
      as_tibble nil>nil
      header_from_row
    
    # Merge the data
    data_tbl <- cbind(main_tbl, stats_tbl)
    
    glimpse(data_tbl)

This gives us a little more of a cleaned up table now, but there&rsquo;s still some work to do.


<a id="org0c2c6b3"></a>

# Clean Up Scraped Data

One thing I&rsquo;d like to fix at this stage is that there are two different &ldquo;Types&rdquo;, Poison and Ghost, that are getting placed into one column. We want to break this up into multiple columns instead such that &ldquo;Type 1&rdquo; is Ghost and &ldquo;Type 2&rdquo; is Poison. We can do this mostly with `strsplit` and `separate` and a little bit of manipulation to make sure we always get up to three different types. No Pokemon so far has more than three types, so this is good for now.

    
    # Clean up the types by breaking them into different columns
    num_types <- data_tbl$Type nil>nil strsplit(" ") nil>nil unlist nil>nil length
    col_names <- paste("Type", c(1:num_types))
    data_tbl <- data_tbl nil>nil
      separate(col = "Type", into = col_names)
    
    # Ensure columns are fixed. Types sometimes only has 1, but can be up to 3.
    cols <- c(
      `Type 1` = NA_character_,
      `Type 2` = NA_character_,
      `Type 3` = NA_character_
    )
    data_tbl <- add_column(data_tbl,
                           !!!cols[setdiff(names(cols), names(data_tbl))])
    
    glimpse(data_tbl)

And now we have our cleaned up Types in different columns. There&rsquo;s more we could do to clean the data, like only have metric units in the Height and Weight columns, but I&rsquo;ll hold that off until we build the full data frame.

    Rows: 1
    Columns: 13
    $ `Type 1`  <chr> "Ghost"
    $ `Type 2`  <chr> "Poison"
    $ Species   <chr> "Shadow Pokémon"
    $ Height    <chr> "1.5 m (4′11″)"
    $ Weight    <chr> "40.5 kg (89.3 lbs)"
    $ HP        <chr> " 60"
    $ Attack    <chr> " 65"
    $ Defense   <chr> " 60"
    $ `Sp. Atk` <chr> "130"
    $ `Sp. Def` <chr> " 75"
    $ Speed     <chr> "110"
    $ Total     <chr> "500"
    $ `Type 3`  <chr> NA


<a id="org35e84a3"></a>

# Add Evolution Data

Finally, let&rsquo;s add some evolution data to our data row. In particular, let&rsquo;s add the following:

-   `Has Evolution`: a boolean flag for if the Pokemon is part of an evolution chain or is a standalone Pokemon. Gengar is part of an evolution chain.
-   `Evolution Place`: an integer stating where in the evolution chain the Pokemon sits. Gengar is the third evolution in its evolution chain.
-   `Maximum Evolution Count`: an integer specifying the final step of the Pokemon&rsquo;s evolution chain. Gengar&rsquo;s evolution chain has three different Pokemon.
-   `Evolution Index`: a floating point value ranging from 0 to 1 specifying where in the evolution chain the Pokemon sits, `Evolution Place/Maximum Evolution Count`. Gengar&rsquo;s evolution index is 1.

    
    # Look for evolution information
    evo_node <- html_nodes(body, "div.infocard-list-evo")
    
    # Check to see if there was any evolution information
    has_evo <- length(evo_node) >= 1
    
    # If there was evolution information, fill out the data
    # Otherwise, assume there is not evolution of this Pokemon
    if (has_evo) {
    
      # Get the list of evolutions
      evo_list <- evo_node nil>nil html_nodes("a.ent-name") nil>nil html_text
    
      # Get the maximum number of evolutions for this Pokemon's evolution chain
      max_evo <- length(unique(evo_list))
    
      # Find out where in the evolution chain this Pokemon sits
      evo_place <- which(tolower(evo_list) == name)[1]
    
      # Calculate an evolution index, how far to max evolution the Pokemon is
      evo_index <- round(as.double(evo_place) / as.double(max_evo), 2)
    
    } else {
    
      # Set the evolution information to NA
      max_evo <- NA_integer_
      evo_place <- NA_integer_
      evo_index <- NA_integer_
    
    }
    
    # Append evolution information to the data tibble
    evo_list <- c(
      `Has Evolution` = has_evo,
      `Evolution Place` = evo_place,
      `Maximum Evolution Count` = max_evo,
      `Evolution Index` = evo_index
    )
    evo_tbl <- evo_list nil>nil t nil>nil as_tibble
    data_tbl <- cbind(data_tbl, evo_tbl)
    
    glimpse(data_tbl)

And that&rsquo;s it! Now we can build on this to create one Pokedex dataframe for all of the different Pokemon on the site.

