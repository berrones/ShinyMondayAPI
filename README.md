# [Shiny Contact Form App](https://berrones.shinyapps.io/ShinyMondayAPI/)

This is a Shiny application that provides a user-friendly contact form integrated with Monday.com's API to submit user information and messages. The app features a responsive design using Bootstrap 5 (via `bslib`) and includes form validation, submission status updates, and a clear form functionality.

## Features
- **Form Inputs**: Users can enter their name, email, and message.
- **Validation**: Ensures all fields are filled, validates name for valid characters, and checks that the message is not empty.
- **Monday.com Integration**: Submits form data to a specified Monday.com board using the API.
- **Responsive UI**: Built with Bootstrap 5 for a modern, mobile-friendly interface.
- **Status Feedback**: Displays real-time submission status with success or error messages.
- **Clear Form**: Allows users to reset the form with a single click.

## Prerequisites
To run this application, you need the following:
- R (version 4.0 or higher)
- Required R packages:
  - `shiny`
  - `bslib`
  - `shinyjs`
  - `httr`
  - `jsonlite`
- A Monday.com account with:
  - An API token (set as the environment variable `api_token`)
  - A board ID (set as the environment variable `board_id`)

## Installation
1. **Install R**: Download and install R from [CRAN](https://cran.r-project.org/).
2. **Install Required Packages**: Run the following in R to install the necessary packages:
   ```R
   install.packages(c("shiny", "bslib", "shinyjs", "httr", "jsonlite"))
   ```
3. **Set Environment Variables**:
   - Set your Monday.com API token and board ID as environment variables:
     ```bash
     export api_token="your_monday_api_token"
     export board_id="your_monday_board_id"
     ```
   - Alternatively, you can set these in your R session:
     ```R
     Sys.setenv(api_token = "your_monday_api_token")
     Sys.setenv(board_id = "your_monday_board_id")
     ```
   - Or, in the app code, ensure the following lines are included before the server function to retrieve the environment variables:
     ```R
     api_token <- Sys.getenv("api_token")
     board_id <- Sys.getenv("board_id")
     ```

## Usage
1. **Save the Code**: Copy the provided R code into a file (e.g., `app.R`).
2. **Run the App**: Open R or RStudio, navigate to the directory containing `app.R`, and run:
   ```R
   library(shiny)
   runApp("app.R")
   ```
3. **Interact with the App**:
   - Open the app in your browser (typically at `http://127.0.0.1:XXXX`).
   - Fill in the name, email, and message fields.
   - Click **Submit** to send the data to Monday.com.
   - Check the status panel for success or error messages.
   - Click **Clear** to reset the form.

## Code Structure
- **UI**:
  - Uses `fluidPage` with `bslib` for a modern Bootstrap 5 theme.
  - Features a two-column layout: one for the form and one for the status.
  - Includes custom CSS for status messages and Font Awesome icons for visual feedback.
- **Server**:
  - Handles form validation for empty fields, invalid name characters, and empty messages.
  - Sends a GraphQL mutation to Monday.com’s API to create a new item.
  - Updates the UI with success or error messages based on the API response.
  - Clears form inputs when the **Clear** button is clicked.
- **Dependencies**:
  - `shiny`: Core framework for the web app.
  - `bslib`: Provides Bootstrap 5 styling.
  - `shinyjs`: Enables JavaScript functionality like form clearing.
  - `httr`: Handles HTTP requests to the Monday.com API.
  - `jsonlite`: Processes JSON responses from the API.

## Environment Variables
- `api_token`: Your Monday.com API token for authentication.
- `board_id`: The ID of the Monday.com board where submissions are stored.

## Notes
- Ensure your Monday.com board has the correct column IDs as specified in the `column_values` variable in the code (`text_mkq6vaar`, `text_mkq6awc2`, `text_mkq6cbxg` for date, message, and email, respectively). Update these if your board uses different column IDs.
- The app assumes the Monday.com API is accessible at `https://api.monday.com/v2`. Check Monday.com’s documentation for any changes to the API endpoint.
- Error handling includes network issues, invalid API responses, and form validation errors.

## Troubleshooting
- **API Errors**: Verify your `api_token` and `board_id`. Ensure the board’s column IDs match those in the code.
- **Form Not Submitting**: Check for empty fields or invalid characters in the name field.
- **App Not Loading**: Ensure all R packages are installed and the environment variables are set correctly.

## License
This project is licensed under the MIT License.

## Acknowledgments
- Built with [Shiny](https://shiny.rstudio.com/) and [Bootstrap 5](https://getbootstrap.com/).
- Integrates with [Monday.com](https://monday.com/) for data submission.
