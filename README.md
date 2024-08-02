Provides a Dart client for accessing the deviantART public endpoints.

## Features

Provides a paginator abstraction for the daily, popular, newest, tags, topics
list, more like this, tag search and top topics endpoints.  The returned JSON is
parsed in to a Dart class representing the response.

- Generic iterator and paginator interface
- Dart objects that represent the JSON data with corresponding fromJson()
  methods:
  * Suggested
  * More Like This
  * Tagged
  * Topic
  * Popular
  * Newest
  * Browse

## Getting started

To get started register an application with the deviantART API here:
https://www.deviantart.com/developers/.  Then set the environment variables:
```bash
export DA_CLIENT_ID=<your client id>
export DA_CLIENT_SECRET=<your client secret>
```

## Usage

```dart
void main() async {
  final client = await ClientBuilder.build();
  final paginator = client.dailyPaginator();
  final response = await paginator.next();
}
```
