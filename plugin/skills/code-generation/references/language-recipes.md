# Language-Specific Generation Recipes

> **Note:** Language support is actively expanding. Operations listed here reflect the current implementation. If an operation fails for a language, it may not yet be supported — check the corpus test scenarios for definitive status.

## TypeScript / JavaScript

**Full DTO:**
```bash
act refactor generate-constructor MyDto --file src/dto/my-dto.ts
act refactor generate-accessors MyDto --file src/dto/my-dto.ts --fields id,name,email
act refactor generate-equals MyDto --file src/dto/my-dto.ts
act refactor generate-hash MyDto --file src/dto/my-dto.ts
act refactor generate-to-string MyDto --file src/dto/my-dto.ts
act refactor generate-to-json MyDto --file src/dto/my-dto.ts
act refactor generate-from-json MyDto --file src/dto/my-dto.ts
act refactor generate-builder MyDto --file src/dto/my-dto.ts
```

**Interface implementation:**
```bash
act refactor generate-impl MyService IMyService --file src/services/my-service.ts
```

**Type guard:**
```bash
act refactor generate-type-guard MyType --file src/types.ts
```

## Python

**Dataclass conversion:**
```bash
act refactor convert-to-dataclass MyClass --file src/models/my_class.py
```

**Full model:**
```bash
act refactor generate-init MyModel --file src/models/my_model.py
act refactor generate-repr MyModel --file src/models/my_model.py
act refactor generate-equals MyModel --file src/models/my_model.py
act refactor generate-hash MyModel --file src/models/my_model.py
act refactor generate-docstring MyModel --file src/models/my_model.py
act refactor add-type-hints MyModel --file src/models/my_model.py
```

## Rust

Rust relies more on derive macros than code generation, but act supports:

```bash
act refactor generate-impl MyStruct MyTrait --file src/models.rs
act refactor generate-builder MyConfig --file src/config.rs
act refactor generate-tests MyStruct --file src/models.rs
```

## Go

```bash
act refactor generate-constructor User --file models/user.go
act refactor generate-to-string User --file models/user.go
act refactor generate-to-json User --file models/user.go
act refactor generate-from-json User --file models/user.go
act refactor generate-tests User --file models/user.go
```

**Go-specific patterns:**
```bash
act refactor add-context-parameter HandleRequest --file handlers/request.go
act refactor wrap-error ValidateInput --file validators/input.go
act refactor wrap-defer OpenConnection --file db/connection.go
```

## C#

```bash
act refactor generate-constructor UserDto --file Models/UserDto.cs
act refactor generate-equals UserDto --file Models/UserDto.cs
act refactor generate-hash UserDto --file Models/UserDto.cs
act refactor generate-to-string UserDto --file Models/UserDto.cs
act refactor convert-to-record UserDto --file Models/UserDto.cs
```

## VB.NET

**Full DTO:**
```bash
act refactor generate-constructor MyDto --file src/MyDto.vb
act refactor generate-accessors MyDto --file src/MyDto.vb
act refactor generate-to-string MyDto --file src/MyDto.vb
act refactor generate-equals MyDto --file src/MyDto.vb
act refactor generate-hash MyDto --file src/MyDto.vb
```

**Constructor only:**
```bash
act refactor generate-constructor MyClass --file src/MyClass.vb
```

**VB.NET-specific operations:**
```bash
act refactor add-option-strict --file src/MyModule.vb
act refactor convert-vbnet-string-interpolation --file src/MyModule.vb --line 5 --column 1
act refactor convert-sub-to-function --file src/MyClass.vb --line 3 --column 1 --return-type Boolean
```

## Dart

**Full model class:**
```bash
act refactor generate-constructor User --file lib/models/user.dart
act refactor generate-accessors User --file lib/models/user.dart
act refactor generate-equals User --file lib/models/user.dart
act refactor generate-hash User --file lib/models/user.dart
act refactor generate-to-string User --file lib/models/user.dart
act refactor generate-to-json User --file lib/models/user.dart
act refactor generate-from-json User --file lib/models/user.dart
```

**Null safety patterns:**
```bash
act refactor add-null-check-dart myVar --file lib/service.dart
act refactor convert-to-nullable String --file lib/models/user.dart
act refactor add-late-modifier myField --file lib/service.dart
act refactor add-required-keyword param --file lib/widgets/my_widget.dart
act refactor add-null-coalescing value --file lib/utils.dart
```

**Flutter widget patterns:**
```bash
act refactor extract-widget --file lib/screens/home.dart --start-line 10 --end-line 30 --name MyCard
act refactor convert-to-stateless-widget MyWidget --file lib/widgets/my_widget.dart
act refactor convert-function-to-widget buildCard --file lib/screens/home.dart
```

**Async/Future patterns:**
```bash
act refactor convert-to-async fetchData --file lib/service.dart
act refactor convert-callback-to-future loadUser --file lib/service.dart
act refactor add-then-chain fetchData --file lib/service.dart
act refactor unwrap-future getUser --file lib/service.dart
```

## Haskell

```bash
act refactor add-deriving MyType --file src/Types.hs
act refactor add-type-signature myFunction --file src/Lib.hs
act refactor generate-instance-stub MyType Show --file src/Types.hs
act refactor generate-smart-constructor MyType --file src/Types.hs
act refactor generate-lens MyType --file src/Types.hs
```

## Objective-C

**Full model class:**
```bash
act refactor generate-constructor MyClass --file src/MyClass.m
act refactor generate-accessors MyClass --file src/MyClass.m --fields name,value
act refactor generate-to-string MyClass --file src/MyClass.m
act refactor generate-equals MyClass --file src/MyClass.m
act refactor generate-hash MyClass --file src/MyClass.m
```

**Import management:**
```bash
act refactor import-add --module Foundation/Foundation.h --file src/MyClass.m
act refactor import-add --module MyHeader.h --file src/MyClass.m
act refactor import-organize --file src/MyClass.m
```

**Objective-C-specific operations:**
```bash
# Add nullability annotations to pointer parameters or properties
act refactor add-nullability-annotation --file src/MyClass.m --line 5 --column 3

# Add @property attributes (nonatomic, strong, copy, readonly, etc.)
act refactor add-property-attribute --file src/MyClass.m --line 8 --attribute nonatomic,strong

# Wrap code in @try/@catch for NSException handling
act refactor wrap-at-try-catch --file src/MyClass.m --start-line 12 --start-column 5 --end-line 14 --end-column 40
```

## Bash

**Harden a script:**
```bash
act refactor add_shebang script.sh
act refactor add_strict_mode script.sh
act refactor add_error_trap script.sh
act refactor add_local_variables deploy --file script.sh
```

**Modernize a script:**
```bash
act refactor convert_backtick_to_subshell --file script.sh
act refactor convert_bracket_to_double_bracket --file script.sh
act refactor convert_echo_to_printf --file script.sh
```

**Extract a reusable function:**
```bash
act refactor extract_function --file script.sh --start-line 12 --end-line 18 --name build_image
```

## Groovy

**Full class with constructor and accessors:**
```bash
act refactor generate-constructor MyClass --file src/MyClass.groovy
act refactor generate-accessors MyClass --file src/MyClass.groovy
act refactor generate-to-string MyClass --file src/MyClass.groovy
act refactor generate-equals MyClass --file src/MyClass.groovy
act refactor generate-hash MyClass --file src/MyClass.groovy
```

**Groovy idiom conversions:**
```bash
act refactor convert-string-to-gstring greet --file src/Service.groovy
act refactor convert-to-safe-navigation processUser --file src/Service.groovy
act refactor convert-to-elvis getValue --file src/Config.groovy
act refactor convert-for-to-each processAll --file src/Processor.groovy
act refactor convert-to-closure transform --file src/Transformer.groovy
act refactor extract-closure process --file src/Processor.groovy
```

**Import management:**
```bash
act refactor convert-static-import sort --file src/Sorter.groovy
act refactor import-organize --file src/Service.groovy
```

**Documentation:**
```bash
act refactor add-groovydoc myMethod --file src/Service.groovy
```

## Perl

**Harden a script with strict mode:**
```bash
act refactor add_strict_warnings --file lib/MyModule.pm
```

**Modernize string concatenation:**
```bash
act refactor convert_concat_to_interpolation --file lib/MyModule.pm
```

**Organize use statements:**
```bash
act refactor organize_use_statements --file lib/MyModule.pm
```

## Lua

**Add local scope:**
```bash
act refactor add-local-declaration --file src/module.lua --line 5 --column 1
```

**Wrap with pcall:**
```bash
act refactor add-pcall-wrapper --file src/module.lua --line 8 --column 1
```

**Convert to method syntax:**
```bash
act refactor convert-to-method-call --file src/module.lua --line 12 --column 1
```

## Clojure

**Rename a function:**
```bash
act refactor rename old-fn-name new-fn-name --file src/core.clj
```

**Delete unused def:**
```bash
act refactor delete unused-constant --file src/core.clj
```

**Add doc comment:**
```bash
act refactor add-doc-comment my-fn --file src/core.clj
```

**Extract a constant:**
```bash
act refactor extract-constant TIMEOUT --file src/config.clj --start-line 5 --start-column 12 --end-line 5 --end-column 17
```

**Wrap with when guard:**
```bash
act refactor wrap-if user --file src/notify.clj --start-line 4 --start-column 3 --end-line 4 --end-column 22
```

**Add require import:**
```bash
act refactor import-add "clojure.string" --file src/core.clj
```

## Julia

**Add type annotation to enable dispatch:**
```bash
act refactor add-type-annotation-julia --file src/math.jl --function-name compute --parameter x --type-name Float64
```

**Create a type-specialised method:**
```bash
act refactor convert-to-multiple-dispatch --file src/math.jl --function-name process --spec "x:Int64" --spec "y:Float64"
```

**Add a docstring:**
```bash
act refactor add-docstring-julia --file src/math.jl --line 3 --docstring "Compute the result for the given input."
```

**Rename a function:**
```bash
act refactor rename old_fn new_fn --file src/module.jl
```

**Extract a constant:**
```bash
act refactor extract-constant MAX_SIZE --file src/config.jl --start-line 5 --start-column 12 --end-line 5 --end-column 14
```

**Wrap with null check:**
```bash
act refactor wrap-null-check --file src/io.jl --variable result --start-line 8 --start-column 5 --end-line 10 --end-column 20
```

## OCaml

**Full record type with constructor:**
```bash
act refactor generate-constructor User --file src/user.ml
act refactor generate-to-string User --file src/user.ml
act refactor generate-equals User --file src/user.ml
act refactor generate-hash User --file src/user.ml
```

**Add type annotation to a binding:**
```bash
act refactor add-type-annotation-ocaml x --file src/config.ml --type-annotation "int"
act refactor add-type-annotation-ocaml greet --file src/greeting.ml --type-annotation "string -> string"
```

**Add deriving attribute (ppx_deriving):**
```bash
act refactor add-deriving-ocaml user --file src/user.ml --derivations "show, eq"
act refactor add-deriving-ocaml point --file src/geometry.ml --derivations "compare, hash"
```

**Make function recursive:**
```bash
act refactor add-rec-keyword factorial --file src/math.ml
act refactor add-rec-keyword map --file src/utils.ml
```

**Wrap with Result error handling:**
```bash
act refactor wrap-result-ocaml parse_int --file src/parser.ml
act refactor wrap-result-ocaml read_file --file src/io.ml
```

**Convert to labeled arguments:**
```bash
act refactor convert-to-labeled-args make_point --file src/geometry.ml
act refactor convert-to-labeled-args create_user --file src/user.ml
```

**Rename a function:**
```bash
act refactor rename greet say_hello --file src/greeting.ml
```

**Extract a variable:**
```bash
act refactor extract-variable product --file src/math.ml --start-line 3 --start-column 14 --end-line 3 --end-column 19
```

**Open a module:**
```bash
act refactor import-add Printf --file src/main.ml
```

**Delete a definition:**
```bash
act refactor delete helper --file src/utils.ml
```

## R

**Full S3 class with constructor and accessors:**
```bash
act refactor generate-constructor MyDto --file R/my-dto.R
act refactor generate-accessors MyDto --file R/my-dto.R
act refactor generate-equals MyDto --file R/my-dto.R
```

**Pipe conversion:**
```bash
act refactor convert-nested-to-pipe --file R/analysis.R
```

**Documentation:**
```bash
act refactor add-roxygen2-docs my_function --file R/utils.R
```

## Solidity

**Rename and extract:**
```bash
act refactor rename deposit newDeposit --file contracts/Token.sol --line 5 --column 14
act refactor extract-function --file contracts/Token.sol --start-line 9 --start-column 9 --end-line 10 --end-column 31 validateTransfer
```

**Gas optimization — require to custom error:**
```bash
act refactor convert-require-to-custom-error --file contracts/Token.sol --line 12 --column 9
```

**Add modifier to function:**
```bash
act refactor add-solidity-modifier --file contracts/Token.sol --line 7 --column 14 onlyOwner
```

**Add event emission:**
```bash
act refactor add-emit-event --file contracts/Token.sol --line 7 --column 14 Transfer
```

**Wrap operations:**
```bash
act refactor wrap-try-catch --file contracts/Token.sol --start-line 8 --start-column 9 --end-line 8 --end-column 50
act refactor wrap-if --file contracts/Token.sol --start-line 8 --start-column 9 --end-line 8 --end-column 50
act refactor wrap-null-check --file contracts/Token.sol --start-line 8 --start-column 9 --end-line 8 --end-column 50
```

## Pascal

**Language-specific operations:**
```bash
act refactor organize-uses-pascal --file src/units/main.pas
act refactor add-property-accessors-pascal --file src/units/person.pas --line 5 --column 5
act refactor convert-procedure-to-function --file src/utils.pas --line 10 --column 1 --return-type Integer
```

## Common Lisp

**Full CLOS DTO (defclass):**
```bash
act refactor generate-constructor person --file src/models/person.lisp
act refactor generate-accessors person --file src/models/person.lisp
act refactor generate-equals person --file src/models/person.lisp
act refactor generate-hash person --file src/models/person.lisp
act refactor generate-to-string person --file src/models/person.lisp
act refactor generate-to-json person --file src/models/person.lisp
act refactor generate-from-json person --file src/models/person.lisp
act refactor generate-builder person --file src/models/person.lisp
```

**Language-specific operations:**
```bash
act refactor convert-if-to-cond --file src/logic.lisp --line 5 --column 1
act refactor convert-progn-to-let --file src/logic.lisp --line 10 --column 1
act refactor add-type-declaration --file src/types.lisp --line 1 --column 1 --target person
```

## COBOL

COBOL is a non-OOP language. Generate operations (constructor, accessors, etc.) are not applicable. Supported operations focus on data manipulation, wrapping, and imports.

**Doc comments:**
```bash
act refactor add-doc-comment --file program.cob --line 8 --column 8 "Main processing paragraph"
```

**Import (COPY) management:**
```bash
act refactor import-add --file program.cob CUSTOMER-REC
act refactor import-remove program.cob CUSTOMER-REC
act refactor import-organize --file program.cob
```

**Wrap operations:**
```bash
act refactor wrap-if --file program.cob --start-line 9 --start-column 12 --end-line 9 --end-column 30 --condition "WS-COUNT > 0"
act refactor wrap-null-check --file program.cob --start-line 9 --start-column 12 --end-line 9 --end-column 30 --variable WS-NAME
act refactor wrap-try-catch --file program.cob --start-line 9 --start-column 12 --end-line 9 --end-column 30
```

**Variable extraction:**
```bash
act refactor extract-variable --file program.cob --start-line 9 --start-column 20 --end-line 9 --end-column 33 WS-MSG
act refactor introduce-variable --file program.cob --start-line 9 --start-column 20 --end-line 9 --end-column 33 WS-VAL
```

**Delete unused:**
```bash
act refactor delete WS-UNUSED
```

**Rename:**
```bash
act refactor rename --file program.cob --line 8 --column 8 NEW-PARA-NAME
```

## PowerShell

PowerShell has language-specific operations for cmdlet conventions and strict mode.

**CmdletBinding and OutputType:**
```bash
act refactor add-cmdlet-binding --file script.ps1 --line 1 --column 1
act refactor add-output-type --file script.ps1 --line 1 --column 1 --type-name "System.String"
```

**Requires statement:**
```bash
act refactor add-requires-statement --file script.ps1 --line 1 --column 1 --module-name PSScriptAnalyzer
```

**Alias expansion:**
```bash
act refactor convert-alias-to-full-cmdlet --file script.ps1 --line 5 --column 1
```

**Write-Host to Write-Output:**
```bash
act refactor convert-write-host-to-write-output --file script.ps1 --line 5 --column 1
```

**Set-StrictMode:**
```bash
act refactor set-strict-mode --file script.ps1 --line 1 --column 1
```

**Common operations:**
```bash
act refactor extract-function --file script.ps1 --start-line 5 --start-column 1 --end-line 10 --end-column 1 New-Function
act refactor extract-variable --file script.ps1 --start-line 5 --start-column 10 --end-line 5 --end-column 20 newVar
act refactor rename --file script.ps1 --line 3 --column 10 NewName
act refactor wrap-try-catch --file script.ps1 --start-line 5 --start-column 1 --end-line 5 --end-column 40
```

## V (vlang.io)

V has language-specific operations for mutability and option types. It uses `fn` for functions, `struct` for data types, and `import module.path` for imports. No semicolons. Null is `none`.

**Add mut modifier to variable:**
```bash
act refactor add-mutable-v --file src/main.v --line 5 --column 5
```

**Convert return type to option:**
```bash
act refactor convert-to-option-v --file src/main.v --line 3 --column 1
```

**Organize imports:**
```bash
act refactor organize-imports-v --file src/main.v
```

**Rename:**
```bash
act refactor rename --file src/main.v --line 3 --column 4 new_name
```

**Wrap in if:**
```bash
act refactor wrap-if --file src/main.v --start-line 5 --start-column 2 --end-line 5 --end-column 30 "x > 0"
```

**Null guard:**
```bash
act refactor wrap-null-check --file src/main.v --start-line 5 --start-column 2 --end-line 5 --end-column 30 ptr
```

## JSON

JSON is a data format with structural transformation operations for refactoring and scaffolding JSON files.

**Scaffolding new JSON structures:**
```bash
act refactor scaffold-empty-object --file config.json --line 1 --column 1
act refactor scaffold-empty-array --file items.json --line 1 --column 1
act refactor scaffold-object-from-keys --file template.json --line 1 --column 1 --keys "id,name,email"
```

**Structural transformations:**
```bash
act refactor rename-key --file data.json --old-key "username" --new-key "user_name"
act refactor merge-objects --file data.json --strategy "merge" --line 1 --line 2
act refactor split-object --file data.json --keys "name,email" --line 1
act refactor flatten-object --file config.json
act refactor expand-object --file config.json
```

**Array operations:**
```bash
act refactor sort-array --file items.json
act refactor deduplicate-array --file tags.json
act refactor reorder-keys --file data.json
```

**Data cleaning:**
```bash
act refactor remove-null-values --file data.json
act refactor remove-empty-values --file data.json
```

## CSS

**Generate design system components:**
```bash
act refactor generate-custom-property --name primary-color --value "#007bff" --file styles.css
act refactor generate-rule-block .button --file styles.css
act refactor generate-media-query --breakpoint 768px --condition min-width --file styles.css
```

**Refactor selectors and properties:**
```bash
act refactor rename-class-selector old-class new-class --file styles.css
act refactor rename-id-selector old-id new-id --file styles.css
act refactor rename-custom-property --old-name primary --new-name brand-primary --file styles.css
```

**Extract and consolidate:**
```bash
act refactor extract-custom-property --value "#007bff" --property-name primary-blue --file styles.css
act refactor extract-selector-group .button --file styles.css
act refactor consolidate-duplicate-selectors .card --file styles.css
act refactor merge-adjacent-rules .card --file styles.css
```

**Convert and standardize:**
```bash
act refactor convert-color-format --source-format hex --target-format rgb --file styles.css
act refactor convert-unit --source-unit px --target-unit rem --base-font-size 16 --file styles.css
act refactor convert-property-value-to-variable --property background-color --value "#007bff" --variable-name primary-blue --file styles.css
```

**Optimize and maintain:**
```bash
act refactor add-vendor-prefix --property display --value flex --file styles.css
act refactor remove-vendor-prefix --property transform --file styles.css
act refactor consolidate-media-queries --file styles.css
act refactor inline-import --file styles.css
act refactor sort-properties .card --file styles.css
```

## Svelte

Svelte is a component framework with reactive declarations, stores, and compile-time directives. Svelte components use `.svelte` files with `<script>`, `<template>`, and `<style>` sections.

**Generate reactive statements:**
```bash
act refactor generate-reactive-statement --file src/components/Counter.svelte --variable count
act refactor generate-reactive-statement --file src/components/User.svelte --variable "user.name"
```

**Generate event dispatchers:**
```bash
act refactor generate-event --file src/components/Button.svelte --event-name click
act refactor generate-event --file src/components/Form.svelte --event-name submit
```

**Generate lifecycle hooks:**
```bash
act refactor generate-lifecycle-hook --file src/components/DataLoader.svelte --hook onMount
act refactor generate-lifecycle-hook --file src/components/Timer.svelte --hook onDestroy
act refactor generate-lifecycle-hook --file src/components/Input.svelte --hook beforeUpdate
act refactor generate-lifecycle-hook --file src/components/List.svelte --hook afterUpdate
```

**Generate control flow blocks:**
```bash
act refactor generate-if-block --file src/components/User.svelte --condition "user.loggedIn"
act refactor generate-each-block --file src/components/List.svelte --item item --array items
act refactor generate-await-block --file src/components/Data.svelte --promise dataPromise
```

**Generate stores:**
```bash
act refactor generate-store --file src/stores/user.ts --store-name user --type-writable
act refactor generate-store --file src/stores/cart.ts --store-name cart --type-readable
act refactor generate-store --file src/stores/theme.ts --store-name theme --type-derived
```

**Generate props from interface:**
```bash
act refactor generate-props-from-interface --file src/components/Button.svelte --interface ButtonProps
```

**Generate SvelteKit route handlers:**
```bash
act refactor generate-route-handler --file src/routes/+page.svelte --handler-type load
act refactor generate-route-handler --file src/routes/+page.server.ts --handler-type action
act refactor generate-route-handler --file src/routes/api/users/+server.ts --handler-type GET
```

**Add directives:**
```bash
act refactor add-bind-directive --file src/components/Input.svelte --property value
act refactor add-bind-directive --file src/components/Checkbox.svelte --property checked
act refactor add-class-directive --file src/components/Card.svelte --class-name active --condition isActive
```

**Add error handling:**
```bash
act refactor add-error-handling-svelte --file src/components/Fetcher.svelte --line 8 --column 1
```

**Add null guards:**
```bash
act refactor add-null-guard-svelte --file src/components/Profile.svelte --variable user
```

**Add type annotations:**
```bash
act refactor add-type-annotation-svelte --file src/components/Counter.svelte --variable count --type number
act refactor add-type-annotation-svelte --file src/components/User.svelte --variable name --type string
```

**Add async/await:**
```bash
act refactor add-missing-async-await-svelte --file src/components/DataLoader.svelte --function fetchData
```

**Convert promise chains to async/await:**
```bash
act refactor convert-promise-chain-to-async-await-svelte --file src/components/API.svelte --line 5 --column 1
```

**Rename events:**
```bash
act refactor rename-event-svelte --file src/components/Button.svelte --old-name click --new-name tap
```

**Rename stores:**
```bash
act refactor rename-store-svelte --file src/stores/user.ts --old-name user --new-name currentUser
```

**Reactive patterns:**
```bash
act refactor generate-reactive-statement --file src/components/Total.svelte --expression "price * quantity"
```

## Verifying Language Support

Run `scripts/language-operation-matrix.sh` to generate a current matrix of which operations are active, skipped, or missing per language.
