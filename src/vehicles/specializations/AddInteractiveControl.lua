------------------------------------------------------------------------------------------------------------------------
---AddInteractiveControl
------------------------------------------------------------------------------------------------------------------------
---Purpose: Specialization placeholder for interactive control installation.
---
---Usage: Copy this specialization into your mod and add this specialization to your custom vehicle
---       type if the interactiveControl specialization isn't installed automatically.
---
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class AddInteractiveControl : Vehicle
AddInteractiveControl = {}

AddInteractiveControl.ADD_INTERACTIVE_CONTROL = true

function AddInteractiveControl.prerequisitesPresent(specializations)
    return true
end
