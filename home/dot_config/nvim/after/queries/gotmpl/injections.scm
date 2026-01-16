; Inject base languages into gotmpl text nodes
; This allows highlighting of the underlying file format (JSON, YAML, etc.)
; while also highlighting the Go template syntax

; Specific injections for common patterns
((text) @injection.content
 (#set! injection.language "bash")
 (#set! injection.combined)
 (#lua-match? @injection.content "^#!/"))

((text) @injection.content
 (#set! injection.language "json")
 (#set! injection.combined)
 (#lua-match? @injection.content "^%s*[{%[]"))

((text) @injection.content
 (#set! injection.language "yaml")
 (#set! injection.combined)
 (#lua-match? @injection.content "^[%w_-]+:"))
