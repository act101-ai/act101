# act Refactor Operation Catalog

These operations are available via the `act` CLI (`act refactor <operation>`). The 6 MCP tools (rename, extract_function, extract_variable, inline, move_symbol, import_organize) are a subset. The remaining operations are CLI-only — invoke them via shell if needed.

## Core Operations (MCP tools available)

| Operation | MCP Tool | Description |
|-----------|----------|-------------|
| Rename | `rename` | Rename symbol + all references |
| Move | `move_symbol` | Move symbol to different file |
| Inline | `inline` | Inline variable/function at usage sites |
| ExtractFunction | `extract_function` | Extract code range to new function |
| ExtractVariable | `extract_variable` | Extract expression to variable |
| ImportOrganize | `import_organize` | Sort and clean imports |

## Extraction (CLI only)

Operations that extract code into new constructs. **These create destination files automatically when needed** (e.g., `extract-class` creates a new file for the extracted class).

| Operation | Description | Languages |
|-----------|-------------|-----------|
| ExtractConstant | Extract value to named constant | All |
| ExtractClass | Extract methods/fields to new class | TS, JS, Python, C#, Java |
| ExtractInterface | Create interface from class | TS, C#, Java |
| ExtractType | Extract inline type to type alias | TS |

## Code Generation (CLI only)

| Operation | Description | Languages |
|-----------|-------------|-----------|
| GenerateConstructor | Generate constructor from fields | TS, JS, Python, C#, Java |
| GenerateImpl | Generate interface/trait implementation stubs | TS, Rust, C#, Go, Java |
| GenerateAccessors | Generate getters/setters | TS, JS, Python, C#, Java |
| GenerateBuilder | Generate builder pattern | TS, Rust, C#, Java |
| GenerateEquals | Generate equals/eq method | TS, JS, Python, C#, Java |
| GenerateHash | Generate hash/hashCode | TS, JS, Python, C#, Java |
| GenerateToString | Generate toString/repr | TS, JS, Python, C#, Java |
| GenerateFromJson | Generate JSON deserialization | TS, Python, Rust, C# |
| GenerateToJson | Generate JSON serialization | TS, Python, Rust, C# |
| GenerateTests | Generate test stubs | All |

## Introduce (CLI only)

| Operation | Description |
|-----------|-------------|
| IntroduceParameter | Convert expression to function parameter |
| IntroduceField | Convert local variable to class field |
| IntroduceVariable | Extract repeated expression to variable |

## Signature Changes (CLI only)

| Operation | Description |
|-----------|-------------|
| ChangeSignature | Modify function parameters/return type |
| ChangeVisibility | Change access modifier |
| ChangeType | Change variable/parameter type |

## Conversions (CLI only)

| Operation | Description | Languages |
|-----------|-------------|-----------|
| ConvertAsync | Convert sync to async | TS, JS, Python |
| ConvertSync | Convert async to sync | TS, JS, Python |
| ConvertPromise | Promise chains to/from async/await | TS, JS |
| ConvertArrow | Function to arrow/lambda | TS, JS |
| ConvertFunction | Arrow to regular function | TS, JS |
| ConvertTernary | if-else to ternary | TS, JS, Python |
| ConvertIfElse | Ternary to if-else | TS, JS, Python |
| ConvertForEach | for loop to forEach/map | TS, JS |
| ConvertFor | forEach/map to for loop | TS, JS |
| ConvertTemplate | String concat to template literal | TS, JS |
| ConvertConcat | Template literal to concat | TS, JS |

## Import Management (CLI only)

| Operation | Description |
|-----------|-------------|
| ImportAdd | Add import statement |
| ImportRemove | Remove import statement |
| ImportAlias | Add/change import alias |

## Wrapping (CLI only)

| Operation | Description |
|-----------|-------------|
| WrapTryCatch | Wrap code in try-catch |
| WrapIf | Wrap code in if statement |
| WrapOptional | Wrap in Optional/Option/Maybe |
| WrapNullCheck | Add null/undefined check guard |

## Structural (CLI only)

| Operation | Description |
|-----------|-------------|
| Encapsulate | Make field private with getter/setter |
| PullUp | Move member to parent class |
| PushDown | Move member to child class(es) |
| Flatten | Flatten nested structure |
| Delete | Delete symbol (only if unused) |
| Split | Split function/class into pieces |
| Combine | Merge related symbols into one |

## Language-Specific Operations

### TypeScript
ConvertInterfaceToType, ConvertTypeToInterface, ConvertEnumToUnion, ConvertUnionToEnum, GenerateTypeGuard, AddTypeAnnotation, AddReadonly, ConvertNamespaceToModule, AddSatisfies, ConvertClassToFunction, AddDiscriminant, ExtractEnumMember, GenerateMappedType, ConvertCallbackToPromise, ConvertRequireToImport, AddBarrelExport

### Python
ConvertFstring, ConvertComprehension, GenerateDocstring, AddDecorator, AddTypeHints, GenerateInit, GenerateRepr, ConvertToDataclass, ConvertFormatPercent, OrganizeImportsPython, ConvertToAsyncPython

### Rust
(Uses core operations: GenerateImpl, GenerateBuilder, etc.)

### Go
ChangeReceiver, AddContextParameter, WrapError, WrapDefer, WrapGoroutine, WrapErrorCheck

### C#
ConvertToRecord, AddNullGuard, ConvertSwitchToExpression, ConvertStringFormatToInterpolation, WrapLock, WrapUsing

### Swift
AddMainActor, AddNonisolated, ConvertToSendable, ConvertClassToActor

### Haskell
AddDeriving, AddTypeSignature, QualifyImport, ExpandImport, OrganizeImports, ConvertPointWise, ConvertPointFree, ConvertDoToBind, ConvertBindToDo, ConvertIfToGuards, ConvertGuardsToIf, ConvertCaseToPattern, ConvertPatternToCase, GenerateInstanceStub, GenerateSmartConstructor, GenerateLens, ExtractWhereBinding, ExtractLetBinding, InlineWhereBinding, DeleteDeclaration, AddImport

### Zig
AddDocComment, AddModuleComment, AddParameterDocs, ConvertVarToLet, ConvertVarToConst, AddDefer, AddErrdefer, ConvertDeferToErrdefer, ConvertCatchToTry, AddCatchHandler, UnwrapWithDefault, AddErrorReturn, ConvertToComptime, MakeParameterComptime, ConvertLoopToInline

### SQL
UppercaseKeywords, LowercaseKeywords, ConvertInnerJoinToLeft, AddColumnAlias, RenameTable

### Dart
AddNullCheckDart, ConvertToNullable, AddLateModifier, AddRequiredKeyword, ConvertNullCheckToOperator, AddNullCoalescing, AddConstConstructor, AddKeyParameter, ExtractWidget, ConvertToStatelessWidget, ConvertFunctionToWidget, ConvertToAsync, ConvertCallbackToFuture, AddThenChain, UnwrapFuture, ConvertToCascade, AddSpreadOperator, ConvertToStringInterpolation, OrganizeImportsDart, ConvertGetterToField

### CSS

| Operation | Category | Description |
|-----------|----------|-------------|
| `rename_class_selector` | Refactoring | Rename CSS class selector across all stylesheets |
| `rename_id_selector` | Refactoring | Rename CSS ID selector across all stylesheets |
| `rename_custom_property` | Refactoring | Rename CSS custom property (--var-name) across all usages |
| `consolidate_duplicate_selectors` | Refactoring | Merge duplicate selectors into single rule with combined properties |
| `extract_custom_property` | Refactoring | Extract repeated property value into named custom property |
| `extract_selector_group` | Refactoring | Extract selector into new rule or add to existing group |
| `convert_property_value_to_variable` | Refactoring | Convert hardcoded property value to custom property reference |
| `add_vendor_prefix` | Refactoring | Add vendor-specific prefix variants (webkit, moz, ms, o) |
| `remove_vendor_prefix` | Refactoring | Remove outdated or unnecessary vendor prefixes |
| `consolidate_media_queries` | Refactoring | Merge duplicate media query blocks into single rule |
| `convert_color_format` | Refactoring | Convert between color formats (hex, rgb, hsl, oklch) |
| `convert_unit` | Refactoring | Convert between CSS units (px, rem, em, %, vw) |
| `sort_properties` | Refactoring | Sort CSS properties by category (layout, typography, color, animation) |
| `inline_import` | Refactoring | Consolidate @import statements into single rule |
| `merge_adjacent_rules` | Refactoring | Combine adjacent rules with same selector into one |
| `generate_rule_block` | Generator | Generate empty CSS rule block for given selector |
| `generate_custom_property` | Generator | Generate CSS custom property declaration in :root |
| `generate_media_query` | Generator | Generate media query block with breakpoint |

**Tier 1 Operations (13 total):** rename_class_selector, rename_id_selector, rename_custom_property, consolidate_duplicate_selectors, extract_custom_property, extract_selector_group, convert_property_value_to_variable, sort_properties, inline_import, merge_adjacent_rules, generate_rule_block, generate_custom_property, organize_rule_properties

**Tier 2 Operations (53 total):** add_vendor_prefix, remove_vendor_prefix, consolidate_media_queries, extract_media_query, convert_color_format, convert_unit, sort_selectors, convert_shorthand, convert_longhand, remove_unnecessary_specificity, extract_shared_properties, add_calc_expression, convert_percentage_to_calc, extract_keyframe_animation, consolidate_font_declarations, remove_duplicate_properties, remove_overridden_properties, expand_nested_selector, convert_to_css_grid_from_flexbox, add_fallback_property, remove_unused_selector, separate_concerns_selector, convert_pseudo_element_colon, remove_empty_rule, add_media_query_support, convert_absolute_to_relative_unit, consolidate_custom_properties, extract_selector_mixin_pattern, convert_hsl_to_oklch, plus 23 additional generator operations (media queries, keyframes, fonts, grid, flexbox, responsive, accessibility, etc.)

### Objective-C

| Operation | Description |
|-----------|-------------|
| `add_nullability_annotation` | Add `_Nullable` or `_Nonnull` annotation to an `@property` pointer type |
| `add_property_attribute` | Add memory-management attribute(s) to an `@property` declaration |
| `wrap_at_try_catch` | Wrap code in an ObjC `@try { } @catch (NSException *e) { }` block |
| `import_add` | Add framework import directive |
| `rename` | Rename a symbol and all references |

### Modern JS/TS Syntax
UseObjectShorthand, AddNullishCoalescing, UseTemplateLiterals, UseDestructuring, AddOptionalChaining, UsePrivateFields, UseRestParameters, UseLogicalAssignment, UseTopLevelAwait, UseSpreadOperator, AddNumericSeparators

## Bash-Specific

### Defensive Scripting
| Operation | Description |
|---|---|
| `add_shebang` | Add or replace shebang with `#!/usr/bin/env bash` |
| `add_strict_mode` | Insert `set -euo pipefail` after shebang |
| `add_errexit` | Insert `set -e` |
| `add_local_variables` | Add `local` to all variable assignments inside a function |
| `add_error_trap` | Insert `trap '...' ERR` handler |
| `wrap_command_check` | Wrap command with `if ! ...; then exit 1; fi` |
| `add_default_value` | Convert `$VAR` to `${VAR:-default}` |
| `add_readonly` | Add `readonly` qualifier to a variable |
| `convert_to_heredoc` | Convert consecutive `echo` lines to `cat <<EOF` block |

### Idiomatic Modernization
| Operation | Description |
|---|---|
| `convert_backtick_to_subshell` | Replace `` `cmd` `` with `$(cmd)` |
| `convert_bracket_to_double_bracket` | Replace `[ ]` with `[[ ]]` in conditionals |
| `convert_echo_to_printf` | Replace `echo` with `printf '%s\n'` |
| `add_array_declaration` | Convert space-separated string to bash array |
| `convert_while_read_to_mapfile` | Replace `while IFS= read -r` loop with `mapfile` |
| `add_integer_attribute` | Add `declare -i` to integer variable declarations |

## Groovy-Specific

| Operation | Description |
|-----------|-------------|
| `convert_string_to_gstring` | Convert string concatenation to GString interpolation (`"Hello ${name}"`) |
| `convert_to_closure` | Convert anonymous class/block to Groovy closure (`{ arg -> body }`) |
| `convert_to_safe_navigation` | Replace null checks with safe navigation operator (`obj?.method()`) |
| `convert_to_elvis` | Replace ternary null checks with Elvis operator (`x ?: default`) |
| `add_groovydoc` | Add `/** */` GroovyDoc comment to method or class |
| `convert_static_import` | Convert `import Foo; Foo.method()` to `import static Foo.method; method()` |
| `extract_closure` | Extract inline closure block to named variable |
| `convert_for_to_each` | Convert Java-style `for (x in list)` to `list.each { x -> }` |

## Perl-Specific

| Operation | Description |
|-----------|-------------|
| `add_strict_warnings` | Add `use strict;` and `use warnings;` pragmas to a Perl file |
| `convert_concat_to_interpolation` | Convert `.` string concatenation to double-quoted variable interpolation |
| `organize_use_statements` | Sort and deduplicate `use` statements (pragmas first, then modules alphabetically) |

## Lua-Specific

| Operation | Description |
|-----------|-------------|
| `add_local_declaration` | Add `local` keyword to a global variable assignment, making it local-scoped |
| `convert_to_method_call` | Convert `obj.method(obj, args)` to `obj:method(args)` using Lua colon syntax |
| `add_pcall_wrapper` | Wrap a function call with `pcall` for protected-mode error handling |

## Jinja-Specific

Jinja is a templating language for Python. The following operations are Tier 1 implementations:

| Operation | Description |
|-----------|-------------|
| `rename_variable` | Rename a template variable and all references |
| `rename_macro` | Rename a macro definition and all call sites |
| `rename_block` | Rename a block definition and all references |
| `extract_macro` | Extract a code block into a reusable macro |
| `extract_block` | Extract a code block into a named block for inheritance |
| `move_block` | Move a block to a different file and add include statement |
| `inline_variable_assignment` | Replace variable with its assigned value |
| `convert_to_import` | Convert macro definitions to imports from macro files |

## Julia-Specific

| Operation | Description |
|-----------|-------------|
| `add_type_annotation_julia` | Add `::Type` annotation to a Julia function parameter (enables multiple dispatch) |
| `convert_to_multiple_dispatch` | Add a type-specialised method alongside the generic function body |
| `add_docstring_julia` | Insert a `"""..."""` triple-quoted docstring before a function or struct definition |

## OCaml-Specific

| Operation | Description |
|-----------|-------------|
| `add_type_annotation_ocaml` | Add `: type` annotation to a `let` binding (e.g., `let x : int = 42`) |
| `add_deriving_ocaml` | Append `[@@deriving attrs]` to a type definition for ppx_deriving code generation |
| `add_rec_keyword` | Insert the `rec` keyword into a function definition to make it recursive |
| `wrap_result_ocaml` | Wrap a function body in `try Ok (...) with exc -> Error exc` for Result-based error handling |
| `convert_to_labeled_args` | Convert positional parameters to labeled arguments (prefix with `~`) |

## Objective-C-Specific

| Operation | Description |
|-----------|-------------|
| `add_nullability_annotation` | Insert `_Nullable` or `_Nonnull` annotation after a pointer type in a method or property declaration |
| `add_property_attribute` | Add an attribute (`nonatomic`, `strong`, `copy`, `readonly`, etc.) to an `@property` declaration |
| `wrap_at_try_catch` | Wrap a code range in an `@try { } @catch (NSException *e) { }` block for Objective-C exception handling |

## Solidity-Specific

| Operation | Description |
|-----------|-------------|
| `add_solidity_modifier` | Add a modifier (`onlyOwner`, `whenNotPaused`, etc.) to a Solidity function declaration |
| `add_emit_event` | Insert an `emit EventName()` statement at the end of a Solidity function body |
| `convert_require_to_custom_error` | Convert `require(condition, "message")` to `if (!condition) revert CustomError()` for gas optimization |

## R-Specific

| Operation | Description |
|-----------|-------------|
| `convert_pipe_to_nested` | Convert magrittr pipe chains (`x %>% f() %>% g()`) to nested function calls (`g(f(x))`) |
| `convert_nested_to_pipe` | Convert nested function calls (`g(f(x))`) to magrittr pipe chains (`x %>% f() %>% g()`) |
| `organize_library_calls` | Sort and deduplicate `library()` and `require()` calls at the top of an R file |

## VB.NET-Specific

| Operation | Description |
|-----------|-------------|
| `add_option_strict` | Add `Option Strict On` and `Option Explicit On` pragmas at the top of a VB.NET file |
| `convert_vbnet_string_interpolation` | Convert `&` string concatenation to `$""` string interpolation |
| `convert_sub_to_function` | Convert a `Sub` declaration to `Function` with a specified return type |

## Pascal-Specific

| Operation | Description |
|-----------|-------------|
| `organize_uses_pascal` | Sort unit names in a Pascal `uses` clause alphabetically |
| `add_property_accessors_pascal` | Generate a read/write property declaration and setter from a Pascal field |
| `convert_procedure_to_function` | Convert a Pascal `procedure` to a `function` by adding a return type |

## Common Lisp-Specific

| Operation | Description |
|-----------|-------------|
| `convert_if_to_cond` | Convert nested `(if ...)` forms to a single `(cond ...)` form |
| `convert_progn_to_let` | Convert `(progn ...)` forms with variable bindings to `(let ...)` |
| `add_type_declaration` | Add `(declaim (type ...))` type declarations for CLOS defclass |

## PowerShell-Specific

| Operation | Description |
|-----------|-------------|
| `add_cmdlet_binding` | Add `[CmdletBinding()]` attribute to a function/script |
| `add_output_type` | Add `[OutputType()]` attribute to a function |
| `add_requires_statement` | Add `#Requires -Module` statement to a script |
| `convert_alias_to_full_cmdlet` | Expand PowerShell aliases to full cmdlet names |
| `convert_write_host_to_write_output` | Convert `Write-Host` calls to `Write-Output` for pipeline compatibility |
| `set_strict_mode` | Add `Set-StrictMode -Version Latest` to a script |

## Svelte-Specific

Svelte is a component framework with reactive declarations, stores, and compile-time directives. Svelte components use `.svelte` files with `<script>`, `<template>`, and `<style>` sections.

| Operation | Description |
|-----------|-------------|
| `add_bind_directive_svelte` | Add `bind:` directive for two-way data binding on form elements or component props |
| `add_class_directive_svelte` | Add `class:` directive for conditional CSS classes based on boolean expression |
| `add_error_handling_svelte` | Wrap async code in try-catch blocks with error state handling |
| `add_missing_async_await_svelte` | Add `async`/`await` keywords to async function calls that are missing them |
| `add_null_guard_svelte` | Add null/undefined check guards before accessing object properties |
| `add_type_annotation_svelte` | Add TypeScript type annotation to variable or function declarations |
| `convert_promise_chain_to_async_await_svelte` | Convert Promise `.then()` chains to `async`/`await` syntax |
| `generate_await_block_svelte` | Generate `{#await promise}...{:then value}...{:catch error}...{/await}` block |
| `generate_each_block_svelte` | Generate `{#each items as item, index (key)}` loop block with optional key and index |
| `generate_event_svelte` | Generate `createEventDispatcher()` call and `dispatch('event')` usage for custom events |
| `generate_if_block_svelte` | Generate `{#if condition}...{:else if}...{:else}...{/if}` conditional block |
| `generate_lifecycle_hook_svelte` | Generate lifecycle hook function (`onMount`, `onDestroy`, `beforeUpdate`, `afterUpdate`) |
| `generate_props_from_interface_svelte` | Generate `export let` props declarations from a TypeScript interface definition |
| `generate_reactive_statement_svelte` | Generate `$:` reactive statement that re-computes when dependencies change |
| `generate_route_handler_svelte` | Generate SvelteKit route handler (`load` function for `+page.ts`, `action` for form handling) |
| `generate_store_svelte` | Generate Svelte store (`writable`, `readable`, or `derived`) with proper typing |
| `rename_event_svelte` | Rename dispatched event and update all `on:event` directive references across components |
| `rename_store_svelte` | Rename store variable and update all `$store` shorthand references |

## COBOL-Specific

COBOL is a non-OOP language. Generate operations (constructor, accessors, etc.) are not applicable. The following common operations are supported:

| Operation | Description |
|-----------|-------------|
| `add_doc_comment` | Add `*>` documentation comment before a paragraph or section |
| `rename` | Rename a paragraph, section, or data item across the program |
| `delete` | Delete an unused data description or paragraph |
| `extract_variable` | Extract an expression into a `MOVE expr TO name` statement |
| `introduce_variable` | Introduce a named variable for an expression |
| `import_add` | Add a `COPY copybook.` statement |
| `import_remove` | Remove a `COPY` statement |
| `import_organize` | Sort and organize `COPY` statements |
| `wrap_if` | Wrap a statement in `IF condition ... END-IF` |
| `wrap_null_check` | Wrap a statement in a `LOW-VALUES` null check |
| `wrap_try_catch` | Wrap statements in COBOL error handling |

## V-Specific

V (vlang.io) is a statically typed systems language. `wrap_optional`, `wrap_lock`, `wrap_using`, `generate_mapped_type`, `generate_type_guard` are not applicable.

| Operation | Description |
|-----------|-------------|
| `add_mutable_v` | Add `mut` modifier before a `:=` variable declaration |
| `convert_to_option_v` | Wrap function return type in `?` (option type) |
| `organize_imports_v` | Sort and deduplicate `import` declarations alphabetically |

## SCSS/Sass

SCSS (Sassy CSS) is a CSS preprocessor with variables, nesting, mixins, functions, and module system. Operations support both `.scss` and `.sass` syntaxes.

**Variable Operations:**
| Operation | Description |
|-----------|-------------|
| `generate_variable_declaration_scss` | Generate SCSS variable declaration (`$name: value;`) |
| `rename_scss_variable` | Rename SCSS variable (`$var`) across all references |
| `remove_unused_variable_scss` | Remove SCSS variables that aren't used |
| `organize_variables_scss` | Group related SCSS variables by category |
| `inline_variable_scss` | Inline SCSS variable usage with its value |
| `add_global_variable_scss` | Add `!global` flag to variable assignment |

**Mixin Operations:**
| Operation | Description |
|-----------|-------------|
| `generate_mixin_scss` | Generate @mixin skeleton with parameters |
| `rename_mixin_scss` | Rename @mixin definition and update @include calls |
| `extract_mixin_scss` | Extract repeated code to @mixin |
| `inline_mixin_scss` | Inline @include back to original code |
| `consolidate_mixins_scss` | Merge similar SCSS mixins |
| `add_mixin_parameter_scss` | Add a parameter to an existing SCSS @mixin |
| `add_mixin_default_param_scss` | Add default value to SCSS mixin parameter |
| `simplify_mixin_logic_scss` | Simplify conditional logic in SCSS mixins |
| `remove_duplicate_mixin_scss` | Remove duplicate SCSS mixin definitions |
| `organize_mixins_scss` | Group SCSS mixins by functionality category |
| `organize_mixins_by_category_scss` | Group mixins by category |

**Function Operations:**
| Operation | Description |
|-----------|-------------|
| `generate_function_scss` | Generate @function skeleton with @return |
| `extract_function_scss` | Extract expression to SCSS @function |
| `inline_function_scss` | Inline SCSS function call back to expression |

**Module System:**
| Operation | Description |
|-----------|-------------|
| `add_use_statement_scss` | Add @use import for SCSS modules |
| `add_forward_statement_scss` | Add @forward for re-exporting SCSS modules |
| `add_extend_directive_scss` | Add @extend directive for selector inheritance |
| `convert_at_import_to_at_use_scss` | Migrate @import to @use (modern Sass module system) |
| `add_module_config_scss` | Add module configuration with @use |

**Nesting Operations:**
| Operation | Description |
|-----------|-------------|
| `simplify_nested_rules_scss` | Flatten unnecessary nesting in SCSS |
| `convert_nested_to_flat_scss` | Convert nested selectors to flat CSS |
| `nest_rule_scss` | Nest rule inside parent selector |
| `unnest_rule_scss` | Unnest rule to flat selector |
| `extract_to_nested_selector_scss` | Extract rule to nested selector |

**List and Map Operations:**
| Operation | Description |
|-----------|-------------|
| `add_list_variable_scss` | Add SCSS list variable (`$list: val1, val2, ...`) |
| `add_map_variable_scss` | Add SCSS map variable (`$name: (key: value)`) |
| `convert_list_to_map_scss` | Convert SCSS list to map structure |

**Control Flow:**
| Operation | Description |
|-----------|-------------|
| `convert_if_to_ternary_scss` | Convert @if/@else to if() ternary when possible |
| `convert_each_to_loop_scss` | Convert @each to explicit loop |

**Component Generators:**
| Operation | Description |
|-----------|-------------|
| `generate_color_map_scss` | Generate color palette map |
| `generate_spacing_map_scss` | Generate spacing scale map |
| `generate_breakpoint_mixin_scss` | Generate responsive breakpoint mixin |
| `generate_media_query_scss` | Generate @media query mixin |
| `generate_button_mixin_scss` | Generate button component mixin |
| `generate_card_mixin_scss` | Generate card component mixin |
| `generate_form_mixin_scss` | Generate form element mixin |
| `generate_animation_mixin_scss` | Generate animation @keyframes mixin |
| `generate_grid_mixin_scss` | Generate CSS grid mixin |
| `generate_flex_mixin_scss` | Generate flexbox mixin |

**Modernization:**
| Operation | Description |
|-----------|-------------|
| `add_interpolation_scss` | Add #{} interpolation |

## Jinja-Specific

Jinja is a template language. Operations support refactoring templates, extracting reusable components (macros, blocks, includes), and generating template constructs. `wrap_try_catch`, `wrap_lock`, `wrap_using` are not applicable.

**Tier 1 Refactorings (8):**

| Operation | Description |
|-----------|-------------|
| `rename_variable` | Rename Jinja variable and all usages in template |
| `rename_macro` | Rename Jinja macro and all invocations |
| `rename_block` | Rename template block definition and references |
| `extract_macro` | Extract template code to reusable macro with parameters |
| `extract_block` | Extract template section to named block (for inheritance) |
| `move_block` | Move block to different position in template hierarchy |
| `inline_variable_assignment` | Inline variable by replacing with its assigned value |
| `convert_to_import` | Convert macro from inline to imported include statement |

**Tier 2 High-Priority Refactorings (3):**

| Operation | Description |
|-----------|-------------|
| `extract_include` | Extract template section to separate `.jinja2` file with include |
| `add_default_filter` | Add default filter to variable expression (`{{ var\|default(...) }}`) |
| `add_escape_filter` | Add escape filter for safe output (`{{ var\|escape }}` or `{{ var\|e }}`) |

**Tier 2 High-Priority Generators (9):**

| Operation | Description |
|-----------|-------------|
| `generate_macro` | Generate macro definition with parameters and body template |
| `generate_block` | Generate block statement for template inheritance |
| `generate_for_loop` | Generate for loop over collection (`{% for item in items %}...{% endfor %}`) |
| `generate_if_block` | Generate conditional block (`{% if condition %}...{% endif %}`) |
| `generate_variable_with_default` | Generate variable set with default value (`{% set var = default %}`) |
| `generate_safe_output` | Generate escaped output expression (`{{ value\|escape }}`) |
| `generate_filter_chain` | Generate expression with chained filters (`{{ value\|lower\|trim }}`) |
| `generate_dict_iteration` | Generate loop over dictionary/object with key-value destructuring |
| `generate_empty_state_block` | Generate conditional empty state display (`{% if not items %}...{% endif %}`) |

## GraphQL-Specific

GraphQL operations support schema design, operation generation, and refactoring. Common operations like rename and extract_fragment work on GraphQL constructs (types, fields, fragments). GraphQL-specific operations handle schema generation and operation creation.

**Tier 1 Refactorings (12):**

| Operation | Description |
|-----------|-------------|
| `rename_type` | Rename GraphQL type and all field references |
| `rename_field` | Rename field in type definition and all usages |
| `rename_argument` | Rename field argument and all call sites |
| `rename_variable` | Rename query/mutation variable and all usages |
| `rename_fragment` | Rename fragment definition and all spreads |
| `extract_fragment` | Extract selection set to reusable fragment |
| `remove_unused_fragment` | Remove fragment definition if not used |
| `remove_unused_variable` | Remove unused query variable |
| `move_field` | Move field between types (refactor schema structure) |
| `inline_fragment_spread` | Inline fragment into query, removing fragment spread |
| `split_selection` | Split selection into separate fragment |
| `merge_selections` | Merge multiple selections into combined query |

**Tier 1 Generators (20):**

| Operation | Description |
|-----------|-------------|
| `generate_object_type` | Generate GraphQL object type definition |
| `generate_input_type` | Generate GraphQL input type definition |
| `generate_enum_type` | Generate GraphQL enum type definition |
| `generate_enum_value` | Add enum value to enum type |
| `generate_field_in_type` | Add field to type definition |
| `generate_query_operation` | Generate query operation skeleton |
| `generate_mutation_operation` | Generate mutation operation skeleton |
| `generate_fragment` | Generate named fragment definition |
| `generate_schema_file` | Generate complete schema file from types |
| `generate_field_resolver_map` | Generate resolver map for type fields |
| `generate_resolver_stub` | Generate resolver function stub |
| `generate_field_type_guard` | Generate TypeScript type guard for field |
| `generate_fragment_types` | Generate TypeScript types from fragment |
| `generate_input_field` | Add field to input type |
| `generate_client_query_hook` | Generate React query hook for operation |
| `generate_mutation_hook` | Generate React mutation hook for operation |
| `generate_query_variables` | Extract and define query variables |
| `extract_query_variables` | Extract hardcoded values to variables |
| `reorganize_schema_fields` | Reorganize fields in type for readability |

All operations support preview mode and undo/redo. Schema changes are atomic and update all dependent queries/fragments automatically.
