## 0.0.1

- Initial package.

## 0.0.2

- fix some know bugs in collection class.

## 0.0.2+1

- fix string data when get data.

## 0.0.2+2

- Change how Map data is stored, and enable document naming using any type.

## 0.0.3

- Create StorageExplorer for manage files and directories, and fix some bugs in document and collection classes.

## 0.0.3+1

- Fix some know bugs.

## 0.0.4

- Create StorageAPI to use it for api requests, and add Network Files service to explorer, and fix multi stream in collection and document.

## 0.0.4+1

- Fix some bugs.

## 0.0.4+2

- Fix some bugs in StorageListeners.

## 0.0.4+3

- Fix some bugs in StorageDocument and StorageCollection.

## 0.0.4+4

- Fix delete and deleteItem in StorageDocument and StorageCollection.

## 0.0.4+5

- Add docs stream in StorageDocument and StorageCollection.

## 0.0.5

- Adding the sync feature to avoid the problem of crashing when reading and writing data, and fix some bugs in StorageExplorer.

## 0.0.5+1

- Fix some bugs in StorageAPI.

## 0.0.5+2

- Fix some bugs.

## 0.0.5+3

- Fix requests headers.

## 0.0.6

- Fix some bugs and removing "api requests caching" feature due to some bugs.

## 0.0.6+1

- Fix dart sdk version error.

## 0.0.6+2

- Fix api request response null return.

## 0.0.6+3

- Fix api response map error exception.

## 0.0.6+4

- Fix network files headers.

## 0.0.6+5

- Fix some bugs.

## 0.0.6+6

- Fix StorageExplorer NetworkFiles clear and fix Image Data error.

## 0.0.6+7

- Fix some bugs.

## 0.0.6+8

- Fix containsKey error.

## 0.0.6+9

- Remove custom path in StorageExplorer and replace it with full path, and fix some bugs in containsKey in StorageDatabaseSource.

## 0.0.6+10

- Fix some bugs in StorageExplorer.

## 0.0.7

- Add Laravel Echo feature and fix some bugs in collection and document streaming.

## 0.0.7+1

- Fix "The data type must be null, but current type is (AnyType)".

## 0.0.8

- Upgrade flutter sdk, laravel_echo_null and socket_io_client packages.

## 0.0.8+1

- Fix laravel_echo migrations, and fix some other know bugs.

## 0.0.8+2

- Fix laravel_echo setup migrations.

## 0.0.8+3

- Fix laravel_echo setup migrations.

## 0.0.8+4

- Fix laravel_echo issues.

## 0.0.8+5

- Upgrade laravel_echo_null to 0.0.5+1.

## 0.0.8+6

- Upgrade laravel_echo_null to 0.0.5+2.

## 0.0.9

- Clean code and set some functions and variables to private and add hasId function to StorageDocument class.

## 0.0.9+1

- Fix has no instance getter 'storageListeners' error.

## 0.0.9+2

- Fix "The method 'addAll' was called on null" error when set data in collection and document.

## 0.0.9+3

- Fix stream error when create document (disable log when creating document).

## 0.0.9+4

- Update Laravel Echo Migration in example to get default values.

## 0.0.10

- Remove documents and use collections directly.

## 0.0.10+1

- Fix some bugs.

## 0.0.10+2

- Upgrade dependencies.

## 1.0.0

- Make it stable.

## 1.0.1

- Fix some bugs.

## 1.0.2

- Fix StorageAPI RequestType.
- Upgrade flutter sdk, and other dependencies.

## 1.0.3

- Clean the code.
- Upgrade flutter sdk, and other dependencies.

## 1.0.4

- Upgrade laravel_echo_null version to 0.0.5+9

## 1.0.5

- Upgrade sdk version.
- Upgrade dependencies versions.
- Make some changes in StorageAPI.
- Update README file.

## 1.0.5+1

- Upgrade the laravel_echo_null version.

## 1.0.5+2

- Clean the code.

## 1.0.5+3

- Fix some bugs.

## 1.0.5+4

- Edit log messages.

## 1.0.6

- Upgrade flutter sdk.
- Upgrade dependencies versions.

## 1.0.6+1

- Upgrade flutter sdk.
- Upgrade dependencies versions.

## 1.0.6+2

- Clean the code.

## 1.0.7

- Upgrade flutter sdk.
- Upgrade dependencies versions.
- Replace `pusher_client_fixed` package with `pusher_client_socket`.

## 1.0.7+1

- Upgrade `laravel_echo_null` package to ^0.0.7+1.
- Upgrade `pusher_client_socket` package to ^0.0.2.

## 1.0.7+2

- Upgrade `laravel_echo_null` package to ^0.0.8.

## 1.0.7+3

- Upgrade flutter sdk.

## 1.0.7+4

- Upgrade flutter sdk.

## 1.0.7+5

- Upgrade flutter sdk.
- Make some changes.

## 1.0.7+6

- Upgrade `laravel_echo_mull` package.

## 1.0.7+7

- Upgrade `laravel_echo_mull` package.

## 1.0.7+8

- Upgrade `laravel_echo_mull` package.

## 1.0.7+9

- Upgrade `laravel_echo_mull` package.

## 2.0.0

- Upgrade flutter sdk.
- Upgrade packages versions.
- Add `StorageModel` feature.

## 2.0.1

- Update `StorageModel` structure.
- Add `StorageModelRegister`.

## 2.0.2

- Export extensions.
- Update `StorageModelRegister`.
- Update `StorageDatabase`.

## 2.0.3

- Upgrade flutter sdk.
- Refactor storage database structure and enhance secure storage functionality.
- Removed deprecated enums from storage_database_values.dart and replaced with storage_database_types.dart.
- Updated StorageListeners to use private \_listenersData map for better encapsulation.
- Modified StorageCollection to include caching mechanisms for improved performance.
- Introduced SecureStorageSource for encrypted data storage with AES encryption.
- Updated stream handling in Explorer classes to use more consistent naming and logic.
- Enhanced error handling and data validation across various storage operations.

## 2.0.4

- Refactor StorageAPI initialization.
- Enhance SecureStorageSource error handling.

## 2.0.5

- Enhance instance management and error handling in StorageAPI, LaravelEcho, and StorageDatabase.
- Refactor StorageModel for improved database interaction.
