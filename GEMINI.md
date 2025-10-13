# Project Overview

This is a Flutter project for a motel management application. It appears to be a cross-platform application, with support for Android, iOS, web, and desktop. The application uses the BLoC pattern for state management, and communicates with a backend server via HTTP and WebSockets.

## Building and Running

To build and run the project, you will need to have the Flutter SDK installed.

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Create a `.env` file** in the root of the project with the following content:
    ```
    BASE_URL=http://<your-backend-server-address>
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Development Conventions

*   **State Management:** The project uses the BLoC (Business Logic Component) pattern for state management.
*   **API Communication:** All communication with the backend server is handled by the `ApiClient` class, which is a singleton. It uses the `http` package for making HTTP requests and `cookie_jar` for session management.
*   **Localization:** The application is localized for the Russian language.
*   **Code Style:** The project uses the `flutter_lints` package to enforce good coding practices.
