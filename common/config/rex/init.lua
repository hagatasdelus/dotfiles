---@class RexCtx
---@field session_id? string
---@field block_id? string
---@field cliend_id? string
---@field origin? string
---@field server? string

---@alias RexKeyHandler fun(ctx: RexCtx, ev: table): boolean?
---@alias RexApiResult table?

---@class RexActionDef
---@field name string  Lowercase letters, digits, and underscores
---@field title string
---@field run fun(ctx: RexCtx, args: table): any
---@field description? string
---@field category? string
---@field keywords? string
---@field args? table  Argument type definition or JSON Schema

---@class RexBinding
---@field key string
---@field mode? string
---@field action? string
---@field fn? function
---@field args? table
---@field source string

---@class RexMode
---@field name string
---@field exclusive boolean
---@field source string

---@class RexHostDef
---@field label string
---@field endpoints? string[]
---@field endpoint? string
---@field id? string
---@field icon? string

---@class RexExecOpts
---@field cwd? string
---@field env? table<string, string|false>
---@field clear_env? boolean
---@field stdin? string|boolean
---@field timeout? number
---@field stdout? boolean|fun(chunk: string)
---@field stderr? boolean|fun(chunk: string)
---@field text? boolean
---@field detach? boolean  (exec.start only)

---@class RexExecResult
---@field code integer
---@field signal? string
---@field stdout string
---@field stderr string
---@field timed_out boolean
---@field ok boolean

---@class RexExecHandle
---@field pid integer
---@field wait fun(self: RexExecHandle, seconds?: number): RexExecResult?, string?
---@field write fun(self: RexExecHandle, data: string): boolean?, string?
---@field close_stdin fun(self: RexExecHandle)
---@field kill fun(self: RexExecHandle, signal?: string|integer)
---@field running fun(self: RexExecHandle): boolean

---@class RexExec
---@overload fun(argv: string[], opts?: RexExecOpts): RexExecResult?, string?
---@field start fun(argv: string[], opts?: RexExecOpts): RexExecHandle?, string?

---@class RexLayout
---@field block fun(spec: { flavor: string, options?: table }): table
---@field horizontal fun(ratio: number, a: table, b: table): table
---@field vertical fun(ratio: number, a: table, b: table): table

---@class Rex
---@field bind fun(key: string, target: string|RexKeyHandler, args?: table)
---@field unbind fun(arg: string|table, target?: string|function): integer
---@field mode fun(name: string, options?: { exclusive?: boolean })
---@field bindings fun(filter?: { key?: string, mode?: string, action?: string }): RexBinding[]
---@field modes fun(): RexMode[]
---@field action fun(def: RexActionDef)
---@field invoke fun(name: string, args?: table): any, string?
---@field client { queue: fun(name: string, args?: table) }
---@field session table<string, fun(args?: table): table?, string?>
---@field call fun(method: string, args?: table): table?, string?
---@field block { call: fun(creator: string, method: string, args?: table): table?, string? }
---@field layout RexLayout
---@field host fun(def: RexHostDef)
---@field servers fun(): string[]
---@field server fun(label: string): table
---@field exec RexExec

---@class RexJson
---@field encode fun(value: any, opts?: { indent?: boolean }): string?, string?
---@field decode fun(text: string): any, string?
---@field json RexJson
---@field log fun(levelOrMessage: string, message?: string)

---@type Rex
---@diagnostic disable-next-line: undefined-global
local rex = rex

-- Shared tmux/Herdr prefix: let the prefix reach programs that use it.
rex.bind("ctrl+q>ctrl+q", "pane.send_key", { key = "ctrl+q" })

-- tmux repeat mode
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+q>r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")

rex.bind("ctrl+q>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+q>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+q>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+q>l", "pane.focus", { direction = "right" })

rex.bind("ctrl+p", "client.tab.previous")
rex.bind("ctrl+n", "client.tab.next")

rex.bind("ctrl+q>shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("repeat/shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("ctrl+q>shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("repeat/shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("ctrl+q>shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("repeat/shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("ctrl+q>shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("repeat/shift+l", "pane.resize", { amount = 5, direction = "right" })

-- Herdr resize mode
rex.mode("resize", { exclusive = true })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")

rex.bind("ctrl+q>shift+4", "session.rename")
rex.bind("ctrl+q>shift+w", "session.new")
rex.bind("ctrl+q>w", "session.switch")
rex.bind("cmd+w", "client.tab.close")
rex.bind("cmd+1", "client.tab.goto", { index = 1 })
rex.bind("cmd+2", "client.tab.goto", { index = 2 })
rex.bind("cmd+3", "client.tab.goto", { index = 3 })
rex.bind("cmd+4", "client.tab.goto", { index = 4 })
rex.bind("cmd+5", "client.tab.goto", { index = 5 })
rex.bind("cmd+6", "client.tab.goto", { index = 6 })
rex.bind("cmd+7", "client.tab.goto", { index = 7 })
rex.bind("cmd+8", "client.tab.goto", { index = 8 })
rex.bind("cmd+9", "client.tab.goto", { index = 9 })
rex.bind("ctrl+q>=", "pane.split", { direction = "right" })
rex.bind("ctrl+q>shift+[Minus]", "pane.split", { direction = "right" })
rex.bind("ctrl+q>shift+[Backslash]", "pane.split", { direction = "right" })
rex.bind("ctrl+q>-", "pane.split", { direction = "down" })
rex.bind("ctrl+q>x", "pane.close")
rex.bind("ctrl+q>z", "pane.zoom")
rex.bind("ctrl+shift+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+shift+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+shift+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+shift+l", "pane.focus", { direction = "right" })
rex.bind("ctrl+shift+p", "session.switch")
rex.bind("ctrl+q>s", "client.mode.enter", { name = "resize" })
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
