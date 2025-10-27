# Make slurmcollie hex sticker


library(hexSticker)
sticker('inst/s_patens.png', 
        package = 'marshmap', 
        p_y = 0.6, p_size=22, 
        p_color = 'black', 
        s_x=1.125, s_y=1.0, s_width=0.9, 
        h_color = 'purple', h_fill = 'white',
        white_around_sticker = FALSE, 
        filename = 'man/figures/hexsticker.png')

