"""Regenerate every art file in ../art. Run: python3 make_all.py (needs Pillow)."""
import make_tiles, make_props, make_buildings, make_chars, make_terrak, make_extras, make_paving, make_flora, make_ui, make_citadel, make_decor
make_tiles.build()
make_props.trees(); make_props.rocks(); make_props.houses(); make_props.market()
make_buildings.wall_texture(); make_buildings.towers(); make_buildings.forge(); make_buildings.castle()
make_chars.characters(); make_chars.items()
make_terrak.sheet(1.6, True, 'terrak_leader.png'); make_terrak.sheet(1.1, False, 'terrak_young.png')
make_extras.build_all()
make_paving.build()
make_flora.build()
make_ui.panel(); make_ui.frame(); make_ui.button(32); make_ui.button(24); make_ui.joystick(); make_ui.small()
make_citadel.build()
make_decor.build()
print('art regenerated')
