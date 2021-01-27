class fdhud : BaseStatusBar
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

        Font fnt = "HUDFONT_DOOM";
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
        
        DrawFDBarHealth(47, 168);
        DrawFDBarArmor(179, 168);
        
        DrawFDBarCurrentAmm(0, 168);
        DrawFDBarKeys(236, 168);
        DrawFDBarAmmo(249, 168);
        
        if (deathmatch || teamplay)
        {
            DrawString(mHUDFont, FormatNumber(CPlayer.FragCount, 3), (138, 171), DI_TEXT_ALIGN_RIGHT);
        }
        else
        {
            DrawFDBarWeapons(104, 168);
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
        int fdbar_weapons_X_pos = -71;
        
        // If true, stack Armor bar on top of Health bar
        if (CVar.GetCVar("fdhud_stackarmorbar", CPlayer).GetBool())
        {
            DrawFDBarHealth(0, -32);
            DrawFDBarArmor(0, -64);
        }
        else
        {
            DrawFDBarHealth(0, -32);
            DrawFDBarArmor(58, -32);
        }
        
        // If true, only show the current weapon ammo
        if (CVar.GetCVar("fdhud_onlycurrentweapon", CPlayer).GetBool())
        {
            DrawFDBarCurrentAmm(-48, -32);
            DrawFDBarKeys(-61, -32);
            fdbar_weapons_X_pos = -60;
        }
        else
        {
            DrawFDBarCurrentAmm(-48, -64);
            DrawFDBarKeys(-61, -64);
            DrawFDBarAmmo(-71, -32);
            fdbar_weapons_X_pos = -71;
        }
        
        // If true, hide the Arms bar
        if (!CVar.GetCVar("fdhud_hidearmsbar", CPlayer).GetBool())
        {
            Vector2 starms_size = TexMan.GetScaledSize(TexMan.CheckForTexture("STARMS", TexMan.TYPE_MiscPatch));
            DrawFDBarWeapons(fdbar_weapons_X_pos - starms_size.X, -32);
        }

        // Draw Inventory bar
        if (isInventoryBarVisible())
        {
            DrawInventoryBar(diparms, (0, 0), 7, DI_SCREEN_CENTER_BOTTOM, HX_SHADOW);
        }
    }

    void DrawFDBarCurrentAmm(int x, int y)
    {
        DrawImage("FDSTAMM", (x, y), DI_ITEM_OFFSETS);
        
        Inventory ammotype1, ammotype2;
        [ammotype1, ammotype2] = GetCurrentAmmo();
        
        if (ammotype1 != null) {
            // Draw icon
            let ammotype = GetInventoryIcon(GetCurrentAmmo(), 0);
            let adjustment = GetTextureOffsetCorrection(ammotype);
            let alpha = CVar.GetCVar("fdhud_ammoiconalpha", CPlayer).GetFloat();
            
            DrawInventoryIcon(GetCurrentAmmo(), (x+24+adjustment.X, y+21+adjustment.Y), DI_ITEM_OFFSETS, alpha);
            
            DrawString(mHUDFont, FormatNumber(mAmmoInterpolator.GetValue(), 3), (x+44, y+3), DI_TEXT_ALIGN_RIGHT|DI_NOSHADOW);
            if (ammotype2 != null) { DrawString(mIndexFont, FormatNumber(mAltAmmoInterpolator.GetValue(), 3), (x+46, y+16), DI_TEXT_ALIGN_RIGHT|DI_NOSHADOW); }
        }
    }

    void DrawFDBarHealth(int x, int y)
    {
        DrawImage("FDSTHP", (x, y), DI_ITEM_OFFSETS);
        
        // Draw icon
        let berserk = CPlayer.mo.FindInventory("PowerStrength");
        
        // Get icon center
        let hpTexID = TexMan.CheckForTexture(berserk? "PSTRA0" : "MEDIA0");
        let adjustment = GetTextureOffsetCorrection(hpTexID);
        let alpha = CVar.GetCVar("fdhud_hpiconalpha", CPlayer).GetFloat();
         
        DrawImage(berserk? "PSTRA0" : "MEDIA0", (x+29+adjustment.X, y+21+adjustment.Y), DI_ITEM_OFFSETS, alpha);
        
        
        DrawString(mHUDFont, FormatNumber(mHealthInterpolator.GetValue(), 3), (x+43, y+3), DI_TEXT_ALIGN_RIGHT|DI_NOSHADOW);
        DrawImage("STTPRCNT", (x+43, y+3), DI_ITEM_OFFSETS);
    }

    void DrawFDBarArmor(int x, int y)
    {
        DrawImage("FDSTARMO", (x, y), DI_ITEM_OFFSETS);
        
        // Draw icon
        let armor = CPlayer.mo.FindInventory("BasicArmor");
        if (armor != null && armor.Amount > 0)
        {
            let armorTexID = GetInventoryIcon(armor, 0);
            let adjustment = GetTextureOffsetCorrection(armorTexID);
            let alpha = CVar.GetCVar("fdhud_armoriconalpha", CPlayer).GetFloat();

            DrawInventoryIcon(armor, (x+29+adjustment.X, y+21+adjustment.Y), DI_ITEM_OFFSETS, alpha);
        }
        
        DrawString(mHUDFont, FormatNumber(mArmorInterpolator.GetValue(), 3), (x+42, y+3), DI_TEXT_ALIGN_RIGHT|DI_NOSHADOW);
        DrawImage("STTPRCNT", (x+42, y+3), DI_ITEM_OFFSETS);
    }

    void DrawFDBarKeys(int x, int y)
    {
        DrawImage("FDSTKEYS", (x, y), DI_ITEM_OFFSETS);
        
        bool locks[6];
        String image;
        for(int i = 0; i < 6; i++) locks[i] = CPlayer.mo.CheckKeys(i + 1, false, true);
        // key 1
        if (locks[1] && locks[4]) image = "STKEYS6";
        else if (locks[1]) image = "STKEYS0";
        else if (locks[4]) image = "STKEYS3";
        DrawImage(image, (x+3, y+3), DI_ITEM_OFFSETS);
        // key 2
        if (locks[2] && locks[5]) image = "STKEYS7";
        else if (locks[2]) image = "STKEYS1";
        else if (locks[5]) image = "STKEYS4";
        else image = "";
        DrawImage(image, (x+3, y+13), DI_ITEM_OFFSETS);
        // key 3
        if (locks[0] && locks[3]) image = "STKEYS8";
        else if (locks[0]) image = "STKEYS2";
        else if (locks[3]) image = "STKEYS5";
        else image = "";
        DrawImage(image, (x+3, y+23), DI_ITEM_OFFSETS);
    }

    void DrawFDBarAmmo(int x, int y)
    {
        DrawImage("FDSTAAMM", (x, y), DI_ITEM_OFFSETS);
    
        DrawString(mIndexFont, FormatNumber(mClipInterpolator.GetValue(), 3), (x+39, y+5), DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxClipInterpolator.GetValue(), 3), (x+65, y+5), DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mShellInterpolator.GetValue(), 3), (x+39, y+11), DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxShellInterpolator.GetValue(), 3), (x+65, y+11), DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mRocketInterpolator.GetValue(), 3), (x+39, y+17), DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxRocketInterpolator.GetValue(), 3), (x+65, y+17), DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mPlasmaInterpolator.GetValue(), 3), (x+39, y+23), DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxPlasmaInterpolator.GetValue(), 3), (x+65, y+23), DI_TEXT_ALIGN_RIGHT);
    }

    void DrawFDBarWeapons(int x, int y)
    {
        DrawImage("STARMS", (x, y), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(2)? "STYSNUM2" : "STGNUM2", (x+7, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(3)? "STYSNUM3" : "STGNUM3", (x+19, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(4)? "STYSNUM4" : "STGNUM4", (x+31, y+4), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(5)? "STYSNUM5" : "STGNUM5", (x+7, y+14), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(6)? "STYSNUM6" : "STGNUM6", (x+19, y+14), DI_ITEM_OFFSETS);
        DrawImage(CPlayer.HasWeaponsInSlot(7)? "STYSNUM7" : "STGNUM7", (x+31, y+14), DI_ITEM_OFFSETS);
    }

    
    Vector2 GetTextureOffsetCorrection(TextureID TexID)
    {
        let offset = TexMan.GetScaledOffset(TexID);
        let size = TexMan.GetScaledSize(TexID);
        
        return (offset.X - int(size.X / 2), offset.Y - size.Y);
    }
}
