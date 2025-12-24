Add-Type -AssemblyName System.Drawing

$images = @(
"assets/images/chest_flat_bench.png",
"assets/images/chest_incline_bench.png",
"assets/images/chest_decline_bench.png",
"assets/images/chest_dumbbell_flies.png",
"assets/images/chest_pullovers.png",
"assets/images/chest_dips.png",
"assets/images/chest_flat_dumbbell_press.png",
"assets/images/chest_incline_dumbbell_press.png",
"assets/images/chest_decline_dumbbell_press.png",

"assets/images/back_bend_over_rows.png",
"assets/images/back_dumbbell_rows.png",
"assets/images/back_deadlift.png",
"assets/images/back_pullups.png",
"assets/images/back_tbar_row.png",
"assets/images/back_lat_pull_down.png",
"assets/images/back_seated_row.png",
"assets/images/back_single_arm_rows.png",
"assets/images/back_reverse_flys.png",
"assets/images/back_bent_arm_pullovers.png",

"assets/images/leg_back_squat.png",
"assets/images/leg_goblet_squat.png",
"assets/images/leg_front_squat.png",
"assets/images/leg_sumo_squat.png",
"assets/images/leg_romanian_deadlift.png",
"assets/images/leg_conventional_deadlift.png",
"assets/images/leg_walking_lunge.png",
"assets/images/leg_reverse_lunge.png",
"assets/images/leg_bulgarian_split.png",
"assets/images/leg_extensions.png",
"assets/images/leg_hamstring_curls.png",
"assets/images/leg_glute_bridges.png"
)

# Arm exercise thumbnails
$images += @(
"assets/images/arm_dumbbell_bicep_curls.png",
"assets/images/arm_hammer_curls.png",
"assets/images/arm_concentration_curls.png",
"assets/images/arm_barbell_curls.png",
"assets/images/arm_preacher_curls.png",
"assets/images/arm_overhead_tricep_extension.png",
"assets/images/arm_tricep_kickbacks.png",
"assets/images/arm_tricep_dips.png",
"assets/images/arm_cross_grip.png",
"assets/images/arm_skull_crusher.png"
)

# Shoulder exercise thumbnails
$images += @(
"assets/images/shoulder_military_barbell_press.png",
"assets/images/shoulder_overhead_dumbbell_press.png",
"assets/images/shoulder_arnold_press.png",
"assets/images/shoulder_lateral_raises.png",
"assets/images/shoulder_front_raises.png",
"assets/images/shoulder_rear_delt_fly.png",
"assets/images/shoulder_upright_row.png",
"assets/images/shoulder_shrugs.png"
)
$colors = @(
[System.Drawing.Color]::FromArgb(255, 52, 152, 219), # blue
[System.Drawing.Color]::FromArgb(255, 46, 204, 113), # green
[System.Drawing.Color]::FromArgb(255, 231, 76, 60),  # red
[System.Drawing.Color]::FromArgb(255, 155, 89, 182), # purple
[System.Drawing.Color]::FromArgb(255, 241, 196, 15), # yellow
[System.Drawing.Color]::FromArgb(255, 230, 126, 34), # orange
[System.Drawing.Color]::FromArgb(255, 149, 165, 166),# gray
[System.Drawing.Color]::FromArgb(255, 26, 188, 156), # teal
[System.Drawing.Color]::FromArgb(255, 52, 73, 94)    # dark
)

foreach ($i in 0..($images.Count - 1)) {
    $path = $images[$i]
    $color = $colors[$i % $colors.Count]

    $dir = [System.IO.Path]::GetDirectoryName($path)
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    $bmp = New-Object System.Drawing.Bitmap 600,400
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($color)

    # draw text label
    $font = New-Object System.Drawing.Font('Segoe UI',24,[System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,255,255))
    $text = [System.IO.Path]::GetFileNameWithoutExtension($path) -replace '_',' '
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = New-Object System.Drawing.RectangleF(0,0,600,400)
    $g.DrawString($text, $font, $brush, $rect, $sf)

    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

Write-Output "Generated $($images.Count) images."