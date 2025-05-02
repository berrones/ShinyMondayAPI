options(bslib.color_contrast_warnings = FALSE)

library(shiny)
library(bslib)
library(shinyjs)
library(httr)
library(jsonlite)

api_token <- Sys.getenv("api_token")
board_id <- Sys.getenv("board_id")

ui <- fluidPage(
  useShinyjs(),
  theme = bs_theme(
    version = 5,
    bg = "#1a1a1a", # Dark background
    fg = "#ffffff", # White text
    primary = "#00ffcc", # Neon cyan
    secondary = "#ff00ff", # Neon magenta
    success = "#39ff14", # Neon green
    danger = "#CC0000", # Darker red for better contrast
    base_font = font_google("Orbitron", wght = c(700)),
    heading_font = font_google("Orbitron", wght = c(900))
  ) |> bs_add_variables(
    "danger-text" = "#ffffff", # Ensure white text on danger backgrounds
    "danger-bg-subtle" = "#660000", # Darker red for hover/focus
    "warning" = "#CC0000", # Match warning to danger for consistency
    "warning-text" = "#ffffff"
  ),
  tags$head(
    tags$style(HTML("
      .status-message {
        padding: 20px;
        border-radius: 10px;
        margin-top: 15px;
        background-color: #2c2c2c;
        box-shadow: 0 0 15px rgba(0, 255, 204, 0.5);
        border: 2px solid #00ffcc;
        font-size: 1.2em;
        font-weight: bold;
        color: #ffffff;
      }
      .card {
        background-color: #262626;
        border: 3px solid #ff00ff;
        box-shadow: 0 0 20px rgba(255, 0, 255, 0.3);
      }
      .card-header {
        background-color: #00ffcc;
        color: #1a1a1a;
        font-size: 1.5em;
        font-weight: 900;
        text-transform: uppercase;
      }
      .btn-primary {
        background-color: #ff00ff;
        border-color: #ff00ff;
        color: #ffffff;
        font-size: 1.3em;
        font-weight: bold;
        text-transform: uppercase;
        box-shadow: 0 0 15px rgba(255, 0, 255, 0.7);
        transition: all 0.3s ease;
      }
      .btn-primary:hover {
        background-color: #ff66ff;
        box-shadow: 0 0 25px rgba(255, 0, 255, 1);
        transform: scale(1.05);
      }
      .btn-warning {
        background-color: #CC0000;
        border-color: #CC0000;
        color: #ffffff;
        font-size: 1.3em;
        font-weight: bold;
        text-transform: uppercase;
        box-shadow: 0 0 15px rgba(204, 0, 0, 0.7);
        transition: all 0.3s ease;
      }
      .btn-warning:hover {
        background-color: #ff3333;
        box-shadow: 0 0 25px rgba(204, 0, 0, 1);
        transform: scale(1.05);
      }
      input, textarea {
        background-color: #333333;
        color: #ffffff;
        border: 2px solid #00ffcc;
        font-size: 1.2em;
        font-weight: 600;
      }
      input:focus, textarea:focus {
        border-color: #ff00ff;
        box-shadow: 0 0 10px rgba(255, 0, 255, 0.5);
      }
      h3 {
        color: #39ff14;
        text-shadow: 0 0 10px rgba(57, 255, 20, 0.8);
      }
      .fa-check-circle {
        color: #39ff14;
        text-shadow: 0 0 10px rgba(57, 255, 20, 0.8);
      }
      .fa-exclamation-circle {
        color: #CC0000;
        text-shadow: 0 0 10px rgba(204, 0, 0, 0.8);
      }
    "))
  ),
  page_fillable(
    layout_columns(
      col_widths = c(8, 4),
      card(
        card_header("Enter Your Information"),
        textInput("name", "Name:", ""),
        textInput("email", "Email:", ""),
        textAreaInput("message", "Message:", "",
          rows = 6,
          resize = "vertical",
          width = "100%"
        ),
        div(
          style = "display: flex; justify-content: space-between; margin-top: 20px;",
          actionButton("submit", "Submit",
            class = "btn-primary",
            icon = icon("right-to-bracket")
          ),
          actionButton("clear_form", "Clear",
            class = "btn-warning",
            icon = icon("eraser")
          )
        )
      ),
      card(
        card_header("Submission Status:"),
        uiOutput("status")
      )
    )
  )
)

server <- function(input, output, session) {
  status_type <- reactiveVal("ready")
  status_message <- reactiveVal("Ready to submit")

  output$status <- renderUI({
    div(
      class = "status-message",
      style = paste0(
        "border-left: 5px solid ",
        if (grepl("Error", status_message())) "#CC0000" else "#39ff14",
        ";"
      ),
      tags$div(
        style = "display: flex; align-items: center;",
        tags$i(
          class = if (grepl("Error", status_message())) "fa fa-exclamation-circle" else "fa fa-check-circle",
          style = paste0(
            "margin-right: 10px; font-size: 30px;"
          )
        ),
        h3(style = "margin: 0; font-weight: 700;", status_message())
      )
    )
  })

  observeEvent(input$submit, {
    if (input$name == "" || input$email == "" || input$message == "") {
      showNotification(
        ui = div(
          tags$b("Error:"),
          "Please fill in all required fields."
        ),
        type = "error",
        duration = 5
      )
      status_type("error")
      status_message("Error: All fields are required!")
      return()
    }

    if (!grepl("^[A-Za-z0-9 ]+$", input$name)) {
      showNotification(
        ui = div(
          tags$b("Error:"),
          "Name contains invalid characters."
        ),
        type = "error",
        duration = 5
      )
      status_type("error")
      status_message("Error: Invalid characters in name!")
      return()
    }

    if (nchar(trimws(input$message)) == 0) {
      showNotification(
        ui = div(
          tags$b("Error:"),
          "Message cannot be empty or only whitespace."
        ),
        type = "error",
        duration = 5
      )
      status_type("error")
      status_message("Error: Message cannot be empty!")
      return()
    }

    status_type("ready")
    status_message("Processing submission...")

    current_date <- format(Sys.Date(), "%Y-%m-%d")

    escaped_message <- gsub('(["\\])', "\\\\\\1", input$message)
    escaped_message <- gsub("\n", "\\n", escaped_message)
    escaped_message <- gsub("\t", "\\t", escaped_message)

    column_values <- paste0(
      "{",
      '"text_mkq6vaar": "', current_date, '",',
      '"text_mkq6awc2": "', escaped_message, '",',
      '"text_mkq6cbxg": "', input$email, '"',
      "}"
    )

    query <- paste0(
      "mutation {",
      "  create_item (",
      "    board_id: ", board_id, ",",
      "    item_name: \"", input$name, "\",",
      "    column_values: \"", gsub('"', '\\\\"', column_values), "\"",
      "  ) {",
      "    id",
      "  }",
      "}"
    )

    response <- tryCatch(
      {
        POST(
          url = "https://api.monday.com/v2",
          add_headers(
            Authorization = api_token,
            "Content-Type" = "application/json"
          ),
          body = list(query = query),
          encode = "json"
        )
      },
      error = function(e) {
        showNotification(
          ui = div(
            tags$b("Error:"),
            "Network issue connecting to Monday.com"
          ),
          type = "error",
          duration = 5
        )
        status_type("error")
        status_message("Error: Network issue connecting to Monday.com")
        return(NULL)
      }
    )

    if (is.null(response)) {
      return()
    }

    response_body <- content(response, "parsed")

    if (status_code(response) == 200 && !is.null(response_body$data$create_item$id)) {
      item_id <- response_body$data$create_item$id
      showNotification(
        ui = div(
          tags$b("Success!"),
          paste("Your message has been submitted. Item ID:", item_id)
        ),
        type = "message",
        duration = 5
      )
      updateTextInput(session, "message", value = "")
      updateTextInput(session, "name", value = "")
      updateTextInput(session, "email", value = "")
      status_type("success")
      status_message(paste("Successfully submitted! Item ID:", item_id))
    } else {
      error_msg <- if (!is.null(response_body$errors)) {
        toJSON(response_body$errors, pretty = TRUE)
      } else {
        "Unknown error"
      }
      showNotification(
        ui = div(
          tags$b("Error!"),
          paste("Status code:", status_code(response), "Details:", error_msg)
        ),
        type = "error",
        duration = 5
      )
      status_type("error")
      status_message(
        paste(
          "Error submitting. Status code:",
          status_code(response),
          "Details:",
          error_msg
        )
      )
    }
  })

  observeEvent(input$clear_form, {
    updateTextInput(session, "message", value = "")
    updateTextInput(session, "name", value = "")
    updateTextInput(session, "email", value = "")
  })
}

shinyApp(ui = ui, server = server)