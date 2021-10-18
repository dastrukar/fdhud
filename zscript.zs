version "4.0"

class FDHud : BaseStatusBar
{
    DynamicValueInterpolator mAmmoInterpolator;
    DynamicValueInterpolator mAltAmmoInterpolator;
    DynamicValueInterpolator mHealthInterpolator;
    DynamicValueInterpolator mArmorInterpolator;

    // Ammo
    DynamicValueInterpolator mClipInterpolator;
    DynamicValueInterpolator mShellInterpolator;
    DynamicValueInterpolator mRocketInterpolator;
    DynamicValueInterpolator mPlasmaInterpolator;

    // Max ammo
    DynamicValueInterpolator mMaxClipInterpolator;
    DynamicValueInterpolator mMaxShellInterpolator;
    DynamicValueInterpolator mMaxRocketInterpolator;
    DynamicValueInterpolator mMaxPlasmaInterpolator;

    HUDFont mHUDFont;
    HUDFont mIndexFont;
    HUDFont mAmountFont;

    InventoryBarState diparms;

    override void Init()
    {
        Super.Init();
        SetSize(32, 320, 200);

        Font fnt = "STATUSFONT";
        mHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft, 1, 1);
        
        fnt = "INDEXFONT_DOOM";
        mIndexFont  = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft);
        mAmountFont = HUDFont.Create("INDEXFONT");
        
        diparms     = InventoryBarState.Create();

        mAmmoInterpolator    = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mAltAmmoInterpolator = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mHealthInterpolator  = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mArmorInterpolator   = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);

        // Ammo
        mClipInterpolator   = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mShellInterpolator  = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mRocketInterpolator = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);
        mPlasmaInterpolator = DynamicValueInterpolator.Create(0, 0.25, 1, 4096);

        // Max Ammo
        mMaxClipInterpolator   = DynamicValueInterpolator.Create(0, 0.25, 1, 4);
        mMaxShellInterpolator  = DynamicValueInterpolator.Create(0, 0.25, 1, 4);
        mMaxRocketInterpolator = DynamicValueInterpolator.Create(0, 0.25, 1, 4);
        mMaxPlasmaInterpolator = DynamicValueInterpolator.Create(0, 0.25, 1, 4);
    }

    override void Draw(int state, double TicFrac)
    {
        Super.Draw(state, TicFrac);

        if (state == HUD_StatusBar)
        {
            BeginStatusBar();
            DrawMainFDBar(TicFrac);
        }
        else if (state == HUD_Fullscreen)
        {
            BeginHUD();
            DrawFDFullScreen();
        }
    }

    override void NewGame()
    {
        Super.NewGame();
        mAmmoInterpolator.Reset(0);
        mAltAmmoInterpolator.Reset(0);
        mHealthInterpolator.Reset(0);
        mArmorInterpolator.Reset(0);

        mClipInterpolator.Reset(0);
        mMaxClipInterpolator.Reset(0);

        mShellInterpolator.Reset(0);
        mMaxShellInterpolator.Reset(0);

        mRocketInterpolator.Reset(0);
        mMaxRocketInterpolator.Reset(0);

        mPlasmaInterpolator.Reset(0);
        mMaxPlasmaInterpolator.Reset(0);
    }

    override void Tick()
    {
        Super.Tick();
        
        Inventory ammotype1, ammotype2;
        [ammotype1, ammotype2] = GetCurrentAmmo();

        if (ammotype1 != null) { mAmmoInterpolator.Update(ammotype1.Amount); }
        if (ammotype2 != null) { mAltAmmoInterpolator.Update(ammotype2.Amount); }

        mHealthInterpolator.Update(CPlayer.health);
        mArmorInterpolator.Update(GetArmorAmount());

        // Ammo
        int amt1, maxamt;
        
        [amt1, maxamt] = GetAmount("Clip");
        mClipInterpolator.Update(amt1);
        mMaxClipInterpolator.Update(maxamt);
        
        [amt1, maxamt] = GetAmount("Shell");
        mShellInterpolator.Update(amt1);
        mMaxShellInterpolator.Update(maxamt);
        
        [amt1, maxamt] = GetAmount("RocketAmmo");
        mRocketInterpolator.Update(amt1);
        mMaxRocketInterpolator.Update(maxamt);
        
        [amt1, maxamt] = GetAmount("Cell");
        mPlasmaInterpolator.Update(amt1);
        mMaxPlasmaInterpolator.Update(maxamt);
    }

    // Most of this is just copied from gzdoom.pk3
    void DrawMainFDBar(double TicFrac)
    {
        DrawImage("STBAR", (0, 168), DI_ITEM_OFFSETS);
        
        DrawFDBarHealth((47, 168));
        DrawFDBarArmor((179, 168));
        
        DrawFDBarCurrentAmm((0, 168));
        DrawFDBarKeys((236, 168));
        DrawFDBarAmmo((249, 168));
        
        if (deathmatch || teamplay)
        {
            DrawString(mHUDFont, FormatNumber(CPlayer.FragCount, 3), (138, 171), DI_TEXT_ALIGN_RIGHT);
        }
        else
        {
            DrawFDBarWeapons((104, 168));
        }
        
        if (multiplayer)
        {
            DrawImage("STFBANY", (143, 168), DI_ITEM_OFFSETS|DI_TRANSLATABLE);
        }
        
        if (CPlayer.mo.InvSel != null && !Level.NoInventoryBar)
        {
            DrawInventoryIcon(CPlayer.mo.InvSel, (160, 198));
            if (CPlayer.mo.InvSel.Amount > 1)
            {
                DrawString(mAmountFont, FormatNumber(CPlayer.mo.InvSel.Amount), (175, 198-mIndexFont.mFont.GetHeight()), DI_TEXT_ALIGN_RIGHT, Font.CR_GOLD);
            }
        }
        else
        {
            DrawTexture(GetMugShot(5), (143, 168), DI_ITEM_OFFSETS);
        }
        if (isInventoryBarVisible())
        {
            DrawInventoryBar(diparms, (48, 169), 7, DI_ITEM_LEFT_TOP);
        }
    }

    void DrawFDFullScreen()
    {
        Vector2 fdbar_weapons_pos = (-71, -64);
        
        // If true, stack Armor bar on top of Health bar
        if (CVar.GetCVar("fdhud_stackarmorbar", CPlayer).GetBool())
        {
            DrawFDBarHealth((0, -32));
            DrawFDBarArmor((0, -64));
        }
        else
        {
            DrawFDBarHealth((0, -32));
            DrawFDBarArmor((58, -32));
        }
        
        // If true, only show the current weapon ammo
        if (CVar.GetCVar("fdhud_onlycurrentweapon", CPlayer).GetBool())
        {
            DrawFDBarCurrentAmm((-48, -32));
            DrawFDBarKeys((-61, -32));
            fdbar_weapons_pos = ((-60, -32));
        }
        else
        {
            DrawFDBarCurrentAmm((-48, -64));
            DrawFDBarKeys((-61, -64));
            DrawFDBarAmmo((-71, -32));
        }
        
        // If true, hide the Arms bar
        if (!CVar.GetCVar("fdhud_hidearmsbar", CPlayer).GetBool())
        {
            Vector2 starms_size = TexMan.GetScaledSize(TexMan.CheckForTexture("STARMS", TexMan.TYPE_MiscPatch));
            DrawFDBarWeapons((fdbar_weapons_pos.X - starms_size.X, -32));
        }

        // Draw Inventory bar
        if (isInventoryBarVisible())
        {
            DrawInventoryBar(diparms, (0, 0), 7, DI_SCREEN_CENTER_BOTTOM, HX_SHADOW);
        }
        else
        {
            // Get position
            Vector2 boxpos = (-diparms.boxsize.X, -diparms.boxsize.Y + fdbar_weapons_pos.Y);
            DrawFDInventory(diparms, boxpos);
        }
    }

    void DrawFDBarCurrentAmm(Vector2 pos)
    {
        DrawImage("FDSTAMM", pos, DI_ITEM_OFFSETS);
        
        Inventory ammotype1, ammotype2;
        [ammotype1, ammotype2] = GetCurrentAmmo();
        
        if (ammotype1 != null) {
            // Get ammo type value
            let ammotype1_value = mAmmoInterpolator.GetValue();
            let ammotype2_value = mAltAmmoInterpolator.GetValue();
            
            // Get format_value
            let format1_value = GetFormatAmount(ammotype1_value);
            let format2_value = GetFormatAmount(ammotype2_value);
            
            // Draw icon
            let ammotype = GetInventoryIcon(GetCurrentAmmo(), 0);
            let alpha = CVar.GetCVar("fdhud_ammoiconalpha", CPlayer).GetFloat();
            
            // Define positions
            let icon_pos = pos + (24, 21);
            let ammo1_pos = pos + (24, 3);
            let ammo2_pos = pos + (46, 16);
            
            DrawInventoryIcon(GetCurrentAmmo(), icon_pos, DI_ITEM_CENTER_BOTTOM, alpha);
            
            // Format ammo
            string ammo1_string;
            string ammo2_string;
            
            if (ammotype2 != null)
            {
                if (CVar.GetCVar("fdhud_swapaltammo", CPlayer).GetBool()) { ammo1_string = FormatNumber(ammotype2_value, format2_value); }
                else { ammo2_string = FormatNumber(ammotype2_value, format2_value); }
            }

            if (ammo1_string != "") { ammo2_string = FormatNumber(ammotype1_value, format1_value); }
            else { ammo1_string = FormatNumber(ammotype1_value, format1_value); }
            
            // Display numbers
            DrawString(mHUDFont, ammo1_string, ammo1_pos, DI_TEXT_ALIGN_CENTER | DI_NOSHADOW);
            if (ammo2_string != "") { DrawString(mIndexFont, ammo2_string, ammo2_pos, DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW); }
        }
    }

    void DrawFDBarHealth(Vector2 pos)
    {
        DrawImage("FDSTHP", pos, DI_ITEM_OFFSETS);
        
        // Get Health value
        let health = mHealthInterpolator.GetValue();

        // Get text_align
        let format_value = GetFormatAmount(health);
        
        // Draw icon
        let berserk = CPlayer.mo.FindInventory("PowerStrength");
        
        let alpha = CVar.GetCVar("fdhud_hpiconalpha", CPlayer).GetFloat();

        // Define positions
        let icon_pos = pos + (29, 21);
        let text_pos = pos + (29, 3);
         
        DrawImage(berserk? "PSTRA0" : "MEDIA0", icon_pos, DI_ITEM_CENTER_BOTTOM, alpha);
        
        // Add percent to health? Also turn it into a string
        string hp;

        hp = FormatNumber(health, format_value);
        if (!CVar.GetCVar("fdhud_hidepercent", CPlayer).GetBool()) { hp = String.Format("%s%%", hp); }
        
        // Draw Health value
        DrawString(mHUDFont, hp, text_pos, DI_TEXT_ALIGN_CENTER|DI_NOSHADOW);
    }

    void DrawFDBarArmor(Vector2 pos)
    {
        DrawImage("FDSTARMO", pos, DI_ITEM_OFFSETS);
        
        // Get Armor value
        let armor_value = mArmorInterpolator.GetValue();
        
        // Get format_value
        let format_value = GetFormatAmount(armor_value);
        
        // Draw icon
        let armor = CPlayer.mo.FindInventory("BasicArmor");
        if (armor != null && armor.Amount > 0)
        {
            let alpha = CVar.GetCVar("fdhud_armoriconalpha", CPlayer).GetFloat();
            
            // Set position
            let icon_pos = pos + (29, 21);

            DrawInventoryIcon(armor, icon_pos, DI_ITEM_CENTER_BOTTOM, alpha);
        }
        
        // Add percent?
        string armor_string = FormatNumber(armor_value, format_value);
        if (!CVar.GetCvar("fdhud_hidepercent", CPlayer).GetBool()) { armor_string = String.Format("%s%%", armor_string); }

        // Set position
        let text_pos = pos + (29, 3);
        
        DrawString(mHUDFont, armor_string, text_pos, DI_TEXT_ALIGN_CENTER|DI_NOSHADOW);
    }

    void DrawFDBarKeys(Vector2 pos)
    {
        DrawImage("FDSTKEYS", pos, DI_ITEM_OFFSETS);
        
        bool locks[6];
        String image;
        
        // Set positions
        let key1_pos = pos + (3, 3);
        let key2_pos = pos + (3, 13);
        let key3_pos = pos + (3, 23);
        
        for(int i = 0; i < 6; i++)
        {
            locks[i] = CPlayer.mo.CheckKeys(i + 1, false, true);
        }

        // key 1
        if (locks[1] && locks[4]) image = "STKEYS6";
        else if (locks[1]) image = "STKEYS0";
        else if (locks[4]) image = "STKEYS3";
        DrawImage(image, key1_pos, DI_ITEM_OFFSETS);

        // key 2
        if (locks[2] && locks[5]) image = "STKEYS7";
        else if (locks[2]) image = "STKEYS1";
        else if (locks[5]) image = "STKEYS4";
        else image = "";
        DrawImage(image, key2_pos, DI_ITEM_OFFSETS);

        // key 3
        if (locks[0] && locks[3]) image = "STKEYS8";
        else if (locks[0]) image = "STKEYS2";
        else if (locks[3]) image = "STKEYS5";
        else image = "";
        DrawImage(image, key3_pos, DI_ITEM_OFFSETS);
    }

    void DrawFDBarAmmo(Vector2 pos)
    {
        DrawImage("FDSTAAMM", pos, DI_ITEM_OFFSETS);

        // Set positions
        let l = 39;
        let r = 65;
        
        // For convience
        let clip_pos  = pos + (l, 5);
        let mclip_pos = pos + (r, 5);
        
        let shell_pos  = pos + (l, 11);
        let mshell_pos = pos + (r, 11);
        
        let rocket_pos  = pos + (l, 17);
        let mrocket_pos = pos + (r, 17);
        
        let plasma_pos  = pos + (l, 23);
        let mplasma_pos = pos + (r, 23);
        
        
        DrawString(mIndexFont, FormatNumber(mClipInterpolator.GetValue(), 3), clip_pos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxClipInterpolator.GetValue(), 3), mclip_pos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mShellInterpolator.GetValue(), 3), shell_pos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxShellInterpolator.GetValue(), 3), mshell_pos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mRocketInterpolator.GetValue(), 3), rocket_pos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxRocketInterpolator.GetValue(), 3), mrocket_pos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mPlasmaInterpolator.GetValue(), 3), plasma_pos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxPlasmaInterpolator.GetValue(), 3), mplasma_pos, DI_TEXT_ALIGN_RIGHT);
    }

    void DrawFDBarWeapons(Vector2 pos)
    {
        DrawImage("STARMS", pos, DI_ITEM_OFFSETS);
        
        let x = pos.X;
        let y = pos.Y;
        
        DrawImage(CPlayer.HasWeaponsInSlot(2)? "STYSNUM2" : "STGNUM2", (x+7, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(3)? "STYSNUM3" : "STGNUM3", (x+19, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(4)? "STYSNUM4" : "STGNUM4", (x+31, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(5)? "STYSNUM5" : "STGNUM5", (x+7, y+14), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(6)? "STYSNUM6" : "STGNUM6", (x+19, y+14), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(7)? "STYSNUM7" : "STGNUM7", (x+31, y+14), DI_ITEM_OFFSETS);
    }

    void DrawFDInventory(InventoryBarState parms, Vector2 pos)
    {
        if (CPlayer.mo.InvSel != null && !Level.NoInventoryBar)
        {
            DrawTexture(parms.box, pos, DI_ITEM_OFFSETS, CVar.GetCVar("fdhud_inventoryalpha", CPlayer).GetFloat());

            Vector2 itempos = pos + parms.boxsize / 2;
            Vector2 textpos = pos + parms.boxsize - (1, 1 + parms.amountfont.mFont.GetHeight());

            let item = CPlayer.mo.InvSel;
            
            // Draw Inventory icon
            DrawInventoryIcon(item, itempos, DI_ITEM_CENTER, CVar.GetCVar("fdhud_inviconalpha", CPlayer).GetFloat());
            if (item.Amount > 1) { DrawString(parms.amountfont, FormatNumber(item.Amount, 0, 5), textpos, DI_TEXT_ALIGN_RIGHT, parms.cr, parms.itemalpha); }
        }
    }

    
    // Returns the length of the given value, used for FormatNumber
    int GetFormatAmount(int value)
    {
        if (CVar.GetCVar("fdhud_centervalue", CPlayer).GetBool())
        {
            int length;
            do
            {
                value /= 10;
                length++;
            }
            while (value >= 1 && length < 3);

            return length;
        }
        else { return 3; }
    }
}
