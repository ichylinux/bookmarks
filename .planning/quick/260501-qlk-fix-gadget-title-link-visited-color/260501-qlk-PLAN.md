# Quick Task 260501-qlk: Fix Gadget Title Link Visited Color

## Goal

Fix the screenshot issue in `tmp/ss.png`: modern theme gadget title bar text should remain white even when the title is a visited link.

## Tasks

1. Update `app/assets/stylesheets/themes/modern.css.scss` so links inside gadget title bars inherit the white title color across normal, visited, hover, active, and focus-visible states.
2. Add a focused asset contract assertion covering visited gadget title links.
3. Run the focused test and lint if available.
