# Constraints

The PGL50H kit's OV5640 reference project contains pin assignments for both
DVP camera ports, but the repository does not yet include a full board top
level or an FDC copied from that reference. The correct pin table depends on
the exact carrier-board revision and the connector orientation.

Before programming hardware, create the project FDC from the matching board
schematic/reference project, assign every active top-level port, and add
clock constraints for both camera PCLK domains and the board system clock.
Do not generate a hardware bitstream from guessed pin locations.
