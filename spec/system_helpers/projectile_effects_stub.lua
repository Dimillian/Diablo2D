local projectileEffects = {}

function projectileEffects.triggerImpact(_world, projectile, _opts)
    local component = projectile.projectile
    if component then
        component.state = "impact"
    end
    -- Movement system will clean up; collision relies on removal after impact.
    -- Stub: no-op in test environment
end

return projectileEffects
