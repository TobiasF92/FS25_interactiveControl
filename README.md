# Interactive Control

'Interactive Control' is a global script mod for Farming Simulator 25.
While this mod is active, you are able to use many other mods that support Interactive Control.
With IC you have the possibility to interactively control many parts of several (prepared) vehicles. to use many other mods that support Interactive Control. With IC you have the possibility to interactively control many parts of several (prepared) vehicles.


## Possibilities

'Interactive Control' provides different possibilities to interact with your vehicles. You can use click icons that appear when you turn on IC or when you are nearby. Another way for interactive handling is a key binding event. The controls are able to use as switch or to force a state.
All interactions are generally possible to use from the inside and the outside of a vehicle.

Using the controls you can steer different things:
* Play animations (e.g. to open/close windows, fold/unfold warning signs, ...)
* Call specific [functions](#FunctionOverview) (e.g. Start/Stop Motor, TurnOn/Off tool, Lift/Lower attacher joints, ...)
* ObjectChanges (to change translation/rotation/visibility/...)

## Thanks goes to:
***Wopster, JoPi, SirJoki80 & Flowsen (for the ui elements) and Face (for the initial idea)***

***& AgrarKadabra for many contributions!***

***VertexDezign & SchnibblModding for testing and providing demo mods!***


## Documentation

The documentation is not finished yet, but should be sufficient for experienced users.


### XML
```xml
<interactiveControl>
    <interactiveControlConfigurations>
        <!-- If needed, you can define different configurations -->
        <interactiveControlConfiguration>
            <interactiveControls>
                <!-- The outdoor trigger is important, if you want to use IC from the outside of a vehicle, you can define a trigger node or load a shared trigger at the linkNode -->
                <outdoorTrigger node="node" linkNode="node" filename="SHARED_INTERACTIVE_TRIGGER" rotation="x y z" translation="x y z" width="5" height="3" length="8"/>

                <!-- Add a new Interactive Control -->
                <interactiveControl negText="$l10n_actionIC_deactivate" posText="$l10n_actionIC_activate">
                    <!-- Add a clickPoint to toggle the event -->
                    <!-- Possible iconTypes: -->
                    <!-- CROSS, IGNITIONKEY, CRUISE_CONTROL, GPS, TURN_ON, ATTACHERJOINTS_LOWER, ATTACHERJOINTS_LIFT, ATTACHERJOINT, LIGHT_HIGH, LIGHT, TURNLIGHT_LEFT, TURNLIGHT_RIGHT, BEACON_LIGHT, ARROW -->
                    <!-- CONVERT INFO: forcedState is now forcedStateValue and type is float -->
                    <clickPoint alignToCamera="true" animMaxLimit="1" animMinLimit="0" animName="string" blinkSpeedScale="1" foldMaxLimit="1" foldMinLimit="0" forcedStateValue="float" direction="1" iconType="CROSS" invertX="false" invertZ="false" node="node" scaleOffset="float" size="0.04" type="UNKNOWN" linkNode="node" rotation="x y z" translation="x y z"/>

                    <!-- Add a button to toggle the event -->
                    <!-- CONVERT INFO: forcedState is now forcedStateValue and type is float -->
                    <button animMaxLimit="1" animMinLimit="0" animName="string" foldMaxLimit="1" foldMinLimit="0" forcedStateValue="float" direction="1" input="string" range="5" refNode="node" type="UNKNOWN"/>

                    <!-- Animation to be played on IC event -->
                    <animation initTime="float" name="string" speedScale="float" />

                    <!-- Add a function to your control, don't forget to add the requirements! -->
                    <!-- CONVERT INFO: some names of the functions changed -->
                    <function name="string">
                        <!-- CONVERT INFO: index and indicies are no longer supported, use indices instead -->
                        <attacherJoint indices="1 2 .. n"/>
                    </function>

                    <!-- This control should not be functional all the time? Add a configuration restriction -->
                    <configurationsRestrictions>
                        <!-- CONVERT INFO: index and indicies are no longer supported, use indices instead -->
                        <restriction indices="1 2 .. n" name="string"/>
                    </configurationsRestrictions>

                    <!-- You want to use some extra dashboards for your control? -->
                    <!-- There are three new valueTypes: ic_state (BOOLEAN) | ic_stateValue (FLOAT 0-1) | ic_action (in combination with 'raiseTime', 'activeTime', 'onICActivate', 'onICDeactivate')-->
                    <dashboard activeTime="1" animName="string" baseColor="string" displayType="string" doInterpolation="false" emissiveScale="0.2" emitColor="string" font="DIGIT" fontThickness="1" groups="string" hasNormalMap="false" hiddenColor="string" idleValue="0" intensity="1" interpolationSpeed="0.005" maxRot="string" maxValueAnim="float" maxValueRot="float" maxValueSlider="float" minRot="string" minValueAnim="float" minValueRot="float" minValueSlider="float" node="node" numberColor="string" numbers="node" onICActivate="true" onICDeactivate="true" precision="1" raiseTime="1" rotAxis="float" textAlignment="RIGHT" textColor="string" textMask="00.0" textScaleX="1" textScaleY="1" textSize="0.03" valueType="string">
                        <state rotation="x y z" scale="x y z" translation="x y z" value="1 2 .. n" visibility="boolean"/>
                    </dashboard>

                    <!-- You can change the active state of dashboards here.-->
                    <!-- Keep in mind to set a value inactive in most entries, not all dashboards are working with the active state -->
                    <!-- Keep in mind that only vanilla dashboard types are supported! -->
                    <dependingDashboards animName="string" dashboardActive="true" dashboardInactive="true" dashboardValueActive="float" dashboardValueInactive="float" node="node" numbers="node"/>

                    <!-- You can block unused moving parts here -->
                    <dependingMovingPart isInactive="true" node="node"/>

                    <!-- You can block unused moving tools here -->
                    <dependingMovingTool isInactive="true" node="node"/>

                    <!-- You can block depending interactive controls here by current value -->
                    <!-- CONVERT INFO: blocking now happens by use of minLimit and maxLimit of depending control-->
                    <dependingInteractiveControl index="int" minLimit="0.0" maxLimit="1.0"/>

                    <!-- Modify sound here, 'indoorFactor' is the sound percentage factor if control is active -->
                    <!-- Set 'delayedSoundAnimationTime' if the sound should be changed on specific animation time (first animation or 'name') -->
                    <soundModifier indoorFactor="float" delayedSoundAnimationTime="float" name="string"/>

                    <objectChange centerOfMassActive="x y z" centerOfMassInactive="x y z" compoundChildActive="boolean" compoundChildInactive="boolean" interpolation="false" interpolationTime="1" massActive="float" massInactive="float" node="node" parentNodeActive="node" parentNodeInactive="node" rigidBodyTypeActive="string" rigidBodyTypeInactive="string" rotationActive="x y z" rotationInactive="x y z" scaleActive="x y z" scaleInactive="x y z" shaderParameter="string" shaderParameterActive="x y z w" shaderParameterInactive="x y z w" sharedShaderParameter="false" translationActive="x y z" translationInactive="x y z" visibilityActive="boolean" visibilityInactive="boolean"/>
                </interactiveControl>
            </interactiveControls>

            <objectChange centerOfMassActive="x y z" centerOfMassInactive="x y z" compoundChildActive="boolean" compoundChildInactive="boolean" interpolation="false" interpolationTime="1" massActive="float" massInactive="float" node="node" parentNodeActive="node" parentNodeInactive="node" rigidBodyTypeActive="string" rigidBodyTypeInactive="string" rotationActive="x y z" rotationInactive="x y z" scaleActive="x y z" scaleInactive="x y z" shaderParameter="string" shaderParameterActive="x y z w" shaderParameterInactive="x y z w" sharedShaderParameter="false" translationActive="x y z" translationInactive="x y z" visibilityActive="boolean" visibilityInactive="boolean"/>
        </interactiveControlConfiguration>
    </interactiveControlConfigurations>

    <!-- If you want to use your own click icon, you easily can register it here -->
    <registers>
        <clickIcon blinkSpeed="float" filename="string" name="string" node="string"/>
    </registers>
</interactiveControl>
```
```xml
<animations>
    <animation>
        <!-- You can block any interactive control using an animation value -->
        <part interactiveControlIndex="integer" interactiveControlBlocked="boolean"/>
    </animation>
</animations>
```


### FunctionOverview:

| Function                                          | Description                                                         | Requirements             |
|---------------------------------------------------|---------------------------------------------------------------------|--------------------------|
| MOTOR_START_STOPP                                 | Toggle vehicle motor start and stop                                 |                          |
| LIGHTS_TOGGLE                                     | Toggle lights on and off                                            |                          |
| LIGHTS_WORKBACK_TOGGLE                            | Toggle worklights back on and off                                   |                          |
| LIGHTS_WORKFRONT_TOGGLE                           | Toggle worklights front on and off                                  |                          |
| LIGHTS_HIGHBEAM_TOGGLE                            | Toggle highbeamlights on and off                                    |                          |
| LIGHTS_TURNLIGHT_HAZARD_TOGGLE                    | Toggle hazard lights on and off                                     |                          |
| LIGHTS_TURNLIGHT_LEFT_TOGGLE                      | Toggle turnlight left on and off                                    |                          |
| LIGHTS_TURNLIGHT_RIGHT_TOGGLE                     | Toggle turnlight right on and off                                   |                          |
| LIGHTS_BEACON_TOGGLE                              | Toggle beaconlight on and off                                       |                          |
| LIGHTS_PIPE_TOGGLE                                | Toggle pipelight on and off                                         |                          |
| AUTOMATIC_STEERING_TOGGLE                         | Toggle automatic steering on and off                                |                          |
| AUTOMATIC_STEERING_LINES_TOGGLE                   | Show/hide automatic steering lines                                  |                          |
| CRUISE_CONTROL_TOGGLE                             | Toggle cruise control on and off                                    |                          |
| DRIVE_DIRECTION_TOGGLE                            | Toggle vehicle drive direction                                      |                          |
| COVER_TOGGLE                                      | Toggle cover state                                                  |                          |
| RADIO_TOGGLE                                      | Toggle radio on/off                                                 |                          |
| RADIO_CHANNEL_NEXT                                | Next radio channel                                                  |                          |
| RADIO_CHANNEL_PREVIOUS                            | Previous radio channel                                              |                          |
| RADIO_ITEM_NEXT                                   | Next radio item                                                     |                          |
| RADIO_ITEM_PREVIOUS                               | Previous radio item                                                 |                          |
| REVERSEDRIVING_TOGGLE                             | Toggle vehicle reverse driving                                      |                          |
| ATTACHERJOINTS_LIFT_LOWER                         | Lift/lower first selected implement in indices                      | ".attacherJoint#indices" |
| TURN_ON_OFF                                       | Turn on/off vehicle                                                 |                          |
| ATTACHERJOINTS_TURN_ON_OFF                        | Turn on/off first selected implement in indices                     | ".attacherJoint#indices" |
| FOLDING_TOGGLE                                    | Fold/unfold vehicle                                                 |                          |
| ATTACHERJOINTS_FOLDING_TOGGLE                     | Fold/unfold first selected implement in indices                     | ".attacherJoint#indices" |
| PIPE_FOLDING_TOGGLE                               | Fold/unfold pipe                                                    |                          |
| DISCHARGE_TOGGLE                                  | Toggle discharging on vehicle                                       |                          |
| ATTACHERJOINTS_DISCHARGE_TOGGLE                   | Toggle discharging on selected attacherJoint if in 'indices'        | ".attacherJoint#indices" |
| CRABSTEERING_TOGGLE                               | Toggle crab steering mode to next mode                              |                          |
| VARIABLE_WORK_WIDTH_LEFT_INCREASE                 | Increase work width left                                            |                          |
| VARIABLE_WORK_WIDTH_LEFT_DECREASE                 | Decrease work width left                                            |                          |
| ATTACHERJOINTS_VARIABLE_WORK_WIDTH_LEFT_INCREASE  | Increase work width left on selected attacherJoint if in 'indices'  | ".attacherJoint#indices" |
| ATTACHERJOINTS_VARIABLE_WORK_WIDTH_LEFT_DECREASE  | Decrease work width left on selected attacherJoint if in 'indices'  | ".attacherJoint#indices" |
| VARIABLE_WORK_WIDTH_RIGHT_INCREASE                | Increase work width right                                           |                          |
| VARIABLE_WORK_WIDTH_RIGHT_DECREASE                | Decrease work width right                                           |                          |
| ATTACHERJOINTS_VARIABLE_WORK_WIDTH_RIGHT_INCREASE | Increase work width right on selected attacherJoint if in 'indices' | ".attacherJoint#indices" |
| ATTACHERJOINTS_VARIABLE_WORK_WIDTH_RIGHT_DECREASE | Decrease work width right on selected attacherJoint if in 'indices' | ".attacherJoint#indices" |
| VARIABLE_WORK_WIDTH_TOGGLE                        | Toggle work width                                                   |                          |
| ATTACHERJOINTS_VARIABLE_WORK_WIDTH_TOGGLE         | Toggle work width on selected attacherJoint if in 'indices'         | ".attacherJoint#indices" |
| ATTACHERJOINTS_ATTACH_DETACH                      | Attach or detach vehicle on attacherJoint if in 'indices'           | ".attacherJoint#indices" |
| BALER_TOGGLE_SIZE                                 | Toggle bale size                                                    |                          |
| BALER_DROP_BALE                                   | Drop bale from baler                                                |                          |
| BALER_TOGGLE_AUTOMATIC_DROP                       | Toggle automatic bale drop from baler                               |                          |
| BALEWRAPPER_DROP_BALE                             | Drop bale from bale wrapper                                         |                          |
| BALEWRAPPER_TOGGLE_AUTOMATIC_DROP                 | Toggle automatic bale drop from bale wrapper                        |                          |

**External Mods**:

| -/- | -/- | -/- |
|-----|-----|-----|


## Copyright

Copyright (c) 2025, John Deere 6930. All rights reserved.
