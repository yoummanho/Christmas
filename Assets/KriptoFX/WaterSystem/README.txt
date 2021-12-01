HDRP Version 1.0.0

My email is "kripto289@gmail.com"
Discord Kripto#6346
Discord channel https://discord.gg/NSXhsnT9Fc
You can contact me for any questions.
My English is not very good, and if I have any translation errors, you can write to me :)


Other resources: 
Galleon https://sketchfab.com/Harry_L
Shark https://sketchfab.com/Ravenloop
Pool https://sketchfab.com/aurelien_martel


DEMO SCENE CORRECT SETTINGS:
1) Import "cinemachine" (for camera motion)
Window -> Package Manager -> click button bellow "packages" tab -> select "All Packages" or "Packages: Unity registry" -> Cinemachine -> "Install"
2) Palms and trees cannot be included in the project under the asset store license, you can download it here http://kripto289.com/AssetStore/WaterSystem/1.1.0/KWS_Trees.unitypackage

WATER FIRST STEPS:
1) Right click in hierarchy -> Effects -> Water system
2) See the description of each setting: just click the help box with the symbol "?" or go over the cursor to any setting to see a text description. 

USING THE FLOWING EDITOR:
1) Click the "Flowmap Painter" button
2) Set the "Flowmap area position" and "Area Size" parameters. You must draw flowmap in this area!
3) Press and hold the left mouse button to draw on the flowmap area.
4) Use the "control" (ctrl) button + left mouse to erase mode.
5) Use the mouse wheel to change the brush size.
6) Press the "Save All" button.
7) All changes will be saved in the folder "Assets/StreamingAssets/WaterSystemData/WaterGUID", so be careful and don't remove it.
You can see the current waterGUID under section "water->rendering tab". It's look like a "74e75fc51de5773448e4fca07d21c2ff"


USING SHORELINE EDITOR:
1) Disable the "selection outline" and "selection wire" in Gizmos (Scene tab -> Gizmos button).
Otherwise shoreline rendering will be slow when you select the water in hierarchy.
2) Click the "Edit mode" button
3) Set the "Drawing area position" and "Shoreline area size" parameters. You must add shoreline waves only in this area!
4) Click the "Add Wave" button. 
You can also add waves to the mouse cursor position using the "Insert" key button. For removal, select a wave and press the "Delete" button.

5) Avoid crossing boxes of the same color! Blue wave boxes should not intersect with other blue boxes. Yellow boxes should not intersect yellow boxes! 
6) You can use move/rotate/scale as usual for any other game object. 
7) Save all changes.
8) All changes will be saved in the folder "Assets/StreamingAssets/WaterSystemData/WaterGUID", so be careful and don't remove it.
You can see the current waterGUID under section "water->rendering tab". It's look like a "74e75fc51de5773448e4fca07d21c2ff"

USING ADDITIONAL FEATURES:
1) You can use the "water depth mask" feature (used for example for ignoring water rendering inside a boat). 
Just create a mesh mask and use shader "KriptoFX/Water/KW_WaterHoleMask"