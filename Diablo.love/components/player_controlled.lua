local function createPlayerControlledComponent(opts)
    opts = opts or {}

    return {
        inputScheme = opts.inputScheme or "keyboard",
    }
end

return createPlayerControlledComponent
