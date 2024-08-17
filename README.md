# devaiantart_client

Provides a Dart client for accessing the deviantART public endpoints.

## Features

The client offers  features to interact with deviantART's public API endpoints:

- **Paginator Abstraction**: Simplifies handling of paginated responses for
  endpoints such as:
  
  * Daily
  * Popular
  * Newest
  * Tags
  * Topics list
  * More like this
  * Tag search
  * Top topics

- **JSON Parsing**: Converts JSON responses into Dart objects, ensuring type
  safety and ease of use. The Dart classes include:

  * Suggested
  * More Like This
  * Tagged
  * Topic
  * Popular
  * Newest
  * Browse

- **Generic Iterator and Paginator Interface**: Provides a unified interface for
  iterating through paginated data, abstracting the complexity of pagination.

## Design

The design of the client focuses on modularity, type safety, and ease of
integration:

- **Client Initialization**: The client is initialized using the `ClientBuilder`
  which handles the setup and configuration.
- **Paginator Classes**: Each endpoint has a corresponding paginator class that
  manages the pagination logic.
- **Dart Data Classes**: Each API response is mapped to a Dart class with a
  `fromJson()` method to facilitate JSON parsing.

## Environment Configuration

Access the API by setting environment variables for client ID and client secret:
  ```bash
  export DA_CLIENT_ID=<your client id>
  export DA_CLIENT_SECRET=<your client secret>
  ```

## Getting Started

To get started, register an application with the deviantART API at:
https://www.deviantart.com/developers/. Set the environment variables for
`DA_CLIENT_ID` and `DA_CLIENT_SECRET` as shown above.

## Example Usage

The following example demonstrates how to initialize the client, create a
paginator for the daily endpoint, and fetch the next set of results:

```dart
void main() async {
  final client = await ClientBuilder.build();
  final paginator = client.dailyPaginator();
  final response = await paginator.next();
}
```

## Tested on

**Platform:**
- macOS Sonoma 14.6.1

**Flutter:**
- Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
- Framework • revision 80c2e84975 (2 weeks ago) • 2024-07-30 23:06:49 +0700
- Engine • revision b8800d88be
- Tools • Dart 3.5.0 • DevTools 2.37.2