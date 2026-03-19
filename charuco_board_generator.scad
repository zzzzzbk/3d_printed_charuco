/* ========================================================================
    CHARUCO BOARD
   1. SETTINGS
      - Setup your board parameter in Customizer -> Geometry settting -> Preview (F5)

   2. EXPORT:
      - Select 'White Base' in Customizer -> Render (F6) -> Export STL.
      - Select 'Black Pattern' in Customizer -> Render (F6) -> Export STL.
      - (Repeat for every Part Index required).

   3. IMPORT:
      - Drag BOTH files into the slicer window AT THE SAME TIME.
      - A dialog will appear: "Load as single object with multiple parts?"
      - Click YES (or "Multi-Part Object").

   4. COLOR ASSIGN:
      - You will see ONE object in the list with two sub-parts.
      - Assign Filament 1 (White) to the total part.
      - Assign Filament 1 (White) to the white sub-part.
      - Assign Filament 2 (Black) to the black sub-part.
    ======================================================================== */

// --- CUSTOMIZER PARAMETERS (MUST BE TOP LEVEL) --------------------------

/* [Export Settings] */
// Controls which component is shown/rendered.
export_mode = "Preview"; // [Preview, White Base, Black Pattern]

/* [Geometry Settings] */
sq_size = 15;             // Grid square size (mm)
marker_size = 11;         // Marker size (mm) - leaves black border
board_cols = 8;          // Number of columns
board_rows = 6;          // Number of rows
border_size = 10;         // Border width (mm) around the chart

// Base thickness (mm).
thickness = 4;

// Depth of the black material flush surface (mm).
surface_layer = 0.6;

/* [Marker Dictionary] */
// DICT_4X4_250 supports marker IDs 0..249.
marker_dict_capacity = 250;
geom_eps = 0.02;          // Small overlap to avoid coplanar boolean artifacts

// --- LIBRARY IMPORT & VALIDATION ----------------------------------------

include <markers_lib.scad>
assert(markers_loaded, "CRITICAL ERROR: 'markers_lib.scad' is missing or outdated. Please run the Python marker generator to create/update the marker library.");

// --- 1. CALCULATIONS & LOGIC --------------------------------------------

effective_thickness = thickness;
inner_w = board_cols * sq_size;
inner_h = board_rows * sq_size;
total_board_w = inner_w + (2 * border_size);
total_board_h = inner_h + (2 * border_size);

label_text = str(board_rows, "x", board_cols , " Grid | ", sq_size, "mm Sq / ", marker_size, "mm Mrk | DICT_4X4_250");

max_marker_id = floor((board_rows * board_cols - 1) / 2);

// --- 2. ERROR CHECKING --------------------------------------------------

assert(board_cols > 0 && board_rows > 0, "CRITICAL ERROR: board_cols and board_rows must be greater than 0.");
assert(sq_size > 0 && marker_size > 0, "CRITICAL ERROR: sq_size and marker_size must be greater than 0.");
assert(marker_size <= sq_size, "CRITICAL ERROR: marker_size must be <= sq_size.");
assert(surface_layer > 0 && surface_layer < effective_thickness, "CRITICAL ERROR: surface_layer must be > 0 and < thickness.");
assert(max_marker_id < marker_dict_capacity, str("CRITICAL ERROR: Board needs marker ID ", max_marker_id, ", but dictionary supports max ", marker_dict_capacity - 1, ". Reduce board size or increase marker library."));

// --- 3. CONSOLE DEBUGGING -----------------------------------------------

echo("=================================================");
echo("   CHARUCO GENERATOR - DEBUG OUTPUT (V42.0)      ");
echo("=================================================");
echo(str("[CONFIG] Grid (Cols x Rows): ", board_cols, " x ", board_rows));
echo(str("[CONFIG] Board Thick       : ", effective_thickness, " mm"));
echo(str("[CONFIG] Square Size       : ", sq_size, " mm"));
echo(str("[CONFIG] Marker Size       : ", marker_size, " mm"));
echo(str("[CONFIG] Border Size       : ", border_size, " mm"));
echo(str("[INFO]   Board Size (W x H): ", total_board_w, " x ", total_board_h, " mm"));
echo(str("[INFO]   Max Marker ID     : ", max_marker_id));
echo(str("[INFO]   Label Text        : ", label_text));
echo("=================================================");

// --- MAIN RENDER MODULE -------------------------------------------------

module render_board() {
    // --- COMPONENT 1: WHITE BASE ---
    if (export_mode == "White Base" || export_mode == "Preview") {
        color("white") difference() {
            // A. Base plate with full border
            translate([-border_size, -border_size, 0])
                cube([total_board_w, total_board_h, effective_thickness]);

            // B. Subtract all black features from white base
            for (x = [0 : board_cols - 1]) {
                for (y = [0 : board_rows - 1]) {
                    global_x = x;
                    global_y = y;

                    if ((global_x + global_y) % 2 == 0) { // Solid black square
                        translate([x * sq_size, y * sq_size, effective_thickness - surface_layer])
                            cube([sq_size, sq_size, surface_layer + 0.1]);
                    }

                    if ((global_x + global_y) % 2 == 1) { // Marker square
                        row_from_top = (board_rows - 1) - global_y;
                        index = row_from_top * board_cols + global_x;
                        id = floor(index / 2);
                        offset = (sq_size - marker_size) / 2;

                        translate([x * sq_size + offset, y * sq_size + offset, effective_thickness - surface_layer]) {
                            translate([0, 0, -geom_eps])
                                draw_marker_black_3d(id, cell = marker_size / 6, height = surface_layer + 2 * geom_eps);
                        }
                    }
                }
            }

            // C. Label (bottom border)
            translate([5, -border_size / 2, effective_thickness - 0.6])
                linear_extrude(1.0)
                text(label_text, size = 3.5, font = "Arial:style=Bold", valign = "center");
        }
    }

    // --- COMPONENT 2: BLACK PATTERN ---
    if (export_mode == "Black Pattern" || export_mode == "Preview") {
        color("black") union() {
            for (x = [0 : board_cols - 1]) {
                for (y = [0 : board_rows - 1]) {
                    global_x = x;
                    global_y = y;

                    if ((global_x + global_y) % 2 == 0) { // Solid black square
                        translate([x * sq_size, y * sq_size, effective_thickness - surface_layer])
                            cube([sq_size, sq_size, surface_layer]);
                    }

                    if ((global_x + global_y) % 2 == 1) { // Marker square
                        row_from_top = (board_rows - 1) - global_y;
                        index = row_from_top * board_cols + global_x;
                        id = floor(index / 2);
                        offset = (sq_size - marker_size) / 2;

                        translate([x * sq_size + offset, y * sq_size + offset, effective_thickness - surface_layer]) {
                            draw_marker_black_3d(id, cell = marker_size / 6, height = surface_layer);
                        }
                    }
                }
            }
        }
    }
}

render_board();

