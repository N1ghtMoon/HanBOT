return {
    id = 'CyrexBaseUlt',
    name = 'Cyrex Base Ult',
    flag = {
      text = "Cyrex",
      color = {
        text = 0xFFEDD7E6,
        background1 = 0xff66ffff,
        background2 = 0x59000000,
      }
    },
    load = function()
      return player.charName == 'Ashe' or player.charName == 'Ezreal' or player.charName == 'Draven' or player.charName == 'Jinx'
    end
}