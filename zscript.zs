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
        
        Inventory ammoType1, ammoType2;
        [ammoType1, ammoType2] = GetCurrentAmmo();

        if (ammoType1 != null)
        {
            mAmmoInterpolator.Update(ammoType1.Amount);
        }

        if (ammoType2 != null)
        {
            mAltAmmoInterpolator.Update(ammoType2.Amount);
        }

        mHealthInterpolator.Update(CPlayer.health);
        mArmorInterpolator.Update(GetArmorAmount());

        // Ammo
        int amt1, maxAmt;
        
        [amt1, maxAmt] = GetAmount("Clip");
        mClipInterpolator.Update(amt1);
        mMaxClipInterpolator.Update(maxAmt);
        
        [amt1, maxAmt] = GetAmount("Shell");
        mShellInterpolator.Update(amt1);
        mMaxShellInterpolator.Update(maxAmt);
        
        [amt1, maxAmt] = GetAmount("RocketAmmo");
        mRocketInterpolator.Update(amt1);
        mMaxRocketInterpolator.Update(maxAmt);
        
        [amt1, maxAmt] = GetAmount("Cell");
        mPlasmaInterpolator.Update(amt1);
        mMaxPlasmaInterpolator.Update(maxAmt);
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
            DrawImage("STFBANY", (143, 168), DI_ITEM_OFFSETS | DI_TRANSLATABLE);
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
        Vector2 weaponsPos = (-71, -64);
        
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
            weaponsPos = ((-60, -32));
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
            Vector2 starmsSize = TexMan.GetScaledSize(TexMan.CheckForTexture("STARMS", TexMan.TYPE_MiscPatch));
            DrawFDBarWeapons((weaponsPos.X - starmsSize.X, -32));
        }

        // Draw Inventory bar
        if (isInventoryBarVisible())
        {
            DrawInventoryBar(diparms, (0, 0), 7, DI_SCREEN_CENTER_BOTTOM, HX_SHADOW);
        }
        else
        {
            // Get position
            Vector2 boxpos = (-diparms.boxsize.X, -diparms.boxsize.Y + weaponsPos.Y);
            DrawFDInventory(diparms, boxpos);
        }
    }

    void DrawFDBarCurrentAmm(Vector2 pos)
    {
        DrawImage("FDSTAMM", pos, DI_ITEM_OFFSETS);
        
        Inventory ammoType1, ammoType2;
        [ammoType1, ammoType2] = GetCurrentAmmo();
        
        if (ammotype1 != null)
        {
            // Get ammo type value
            let ammoTypeValue1 = mAmmoInterpolator.GetValue();
            let ammoTypeValue2 = mAltAmmoInterpolator.GetValue();
            
            // Get format_value
            let formatValue1 = GetFormatAmount(ammoTypeValue1);
            let formatValue2 = GetFormatAmount(ammoTypeValue2);
            
            // Draw icon
            let ammoType = GetInventoryIcon(GetCurrentAmmo(), 0);
            let alpha = CVar.GetCVar("fdhud_ammoiconalpha", CPlayer).GetFloat();
            
            // Define positions
            let iconPos = pos + (24, 21);
            let ammoPos1 = pos + (24, 3);
            let ammoPos2 = pos + (46, 16);
            
            DrawInventoryIcon(GetCurrentAmmo(), iconPos, DI_ITEM_CENTER_BOTTOM, alpha);
            
            // Format ammo
            string ammoString1;
            string ammoString2;
            
            if (ammoType2 != null)
            {
                if (CVar.GetCVar("fdhud_swapaltammo", CPlayer).GetBool())
                {
                    ammoString1 = FormatNumber(ammoTypeValue2, formatValue2);
                }
                else
                {
                    ammoString2 = FormatNumber(ammoTypeValue2, formatValue2);
                }
            }

            if (ammoString1 != "")
            {
                ammoString2 = FormatNumber(ammoTypeValue1, formatValue1);
            }
            else
            {
                ammoString1 = FormatNumber(ammoTypeValue1, formatValue1);
            }
            
            // Display numbers
            DrawString(mHUDFont, ammoString1, ammoPos1, DI_TEXT_ALIGN_CENTER | DI_NOSHADOW);
            if (ammoString2 != "")
            {
                DrawString(mIndexFont, ammoString2, ammoPos2, DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW);
            }
        }
    }

    void DrawFDBarHealth(Vector2 pos)
    {
        DrawImage("FDSTHP", pos, DI_ITEM_OFFSETS);
        
        // Get Health value
        let health = mHealthInterpolator.GetValue();

        // Get text_align
        let formatValue = GetFormatAmount(health);
        
        // Draw icon
        let berserk = CPlayer.mo.FindInventory("PowerStrength");
        
        let alpha = CVar.GetCVar("fdhud_hpiconalpha", CPlayer).GetFloat();

        // Define positions
        let iconPos = pos + (29, 21);
        let textPos = pos + (29, 3);
         
        DrawImage(berserk? "PSTRA0" : "MEDIA0", iconPos, DI_ITEM_CENTER_BOTTOM, alpha);
        
        // Add percent to health? Also turn it into a string
        string hp;

        hp = FormatNumber(health, formatValue);
        if (!CVar.GetCVar("fdhud_hidepercent", CPlayer).GetBool()) { hp = String.Format("%s%%", hp); }
        
        // Draw Health value
        DrawString(mHUDFont, hp, textPos, DI_TEXT_ALIGN_CENTER | DI_NOSHADOW);
    }

    void DrawFDBarArmor(Vector2 pos)
    {
        DrawImage("FDSTARMO", pos, DI_ITEM_OFFSETS);
        
        // Get Armor value
        let armorValue = mArmorInterpolator.GetValue();
        
        // Get format_value
        let formatValue = GetFormatAmount(armorValue);
        
        // Draw icon
        let armor = CPlayer.mo.FindInventory("BasicArmor");
        if (armor != null && armor.Amount > 0)
        {
            let alpha = CVar.GetCVar("fdhud_armoriconalpha", CPlayer).GetFloat();
            
            // Set position
            let iconPos = pos + (29, 21);

            DrawInventoryIcon(armor, iconPos, DI_ITEM_CENTER_BOTTOM, alpha);
        }
        
        // Add percent?
        string armorString = FormatNumber(armorValue, formatValue);
        if (!CVar.GetCvar("fdhud_hidepercent", CPlayer).GetBool())
        {
            armorString = String.Format("%s%%", armorString);
        }

        // Set position
        let textPos = pos + (29, 3);
        
        DrawString(mHUDFont, armorString, textPos, DI_TEXT_ALIGN_CENTER | DI_NOSHADOW);
    }

    void DrawFDBarKeys(Vector2 pos)
    {
        DrawImage("FDSTKEYS", pos, DI_ITEM_OFFSETS);

        bool locks[6];
        String image;

        // Set positions
        let keyPos1 = pos + (3, 3);
        let keyPos2 = pos + (3, 13);
        let keyPos3 = pos + (3, 23);

        for(int i = 0; i < 6; i++)
        {
            locks[i] = CPlayer.mo.CheckKeys(i + 1, false, true);
        }

        // key 1
        if (locks[1] && locks[4]) image = "STKEYS6";
        else if (locks[1]) image = "STKEYS0";
        else if (locks[4]) image = "STKEYS3";
        DrawImage(image, keyPos1, DI_ITEM_OFFSETS);
        // key 2
        if (locks[2] && locks[5]) image = "STKEYS7";
        else if (locks[2]) image = "STKEYS1";
        else if (locks[5]) image = "STKEYS4";
        else image = "";
        DrawImage(image, keyPos2, DI_ITEM_OFFSETS);
        // key 3
        if (locks[0] && locks[3]) image = "STKEYS8";
        else if (locks[0]) image = "STKEYS2";
        else if (locks[3]) image = "STKEYS5";
        else image = "";
        DrawImage(image, keyPos3, DI_ITEM_OFFSETS);
    }

    void DrawFDBarAmmo(Vector2 pos)
    {
        DrawImage("FDSTAAMM", pos, DI_ITEM_OFFSETS);

        // Set positions
        let l = 39;
        let r = 65;
        
        // For convience
        let clipPos  = pos + (l, 5);
        let mClipPos = pos + (r, 5);
        
        let shellPos  = pos + (l, 11);
        let mShellPos = pos + (r, 11);
        
        let rocketPos  = pos + (l, 17);
        let mRocketPos = pos + (r, 17);
        
        let plasmaPos  = pos + (l, 23);
        let mPlasmaPos = pos + (r, 23);
        
        
        DrawString(mIndexFont, FormatNumber(mClipInterpolator.GetValue(), 3), clipPos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxClipInterpolator.GetValue(), 3), mClipPos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mShellInterpolator.GetValue(), 3), shellPos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxShellInterpolator.GetValue(), 3), mShellPos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mRocketInterpolator.GetValue(), 3), rocketPos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxRocketInterpolator.GetValue(), 3), mRocketPos, DI_TEXT_ALIGN_RIGHT);

        DrawString(mIndexFont, FormatNumber(mPlasmaInterpolator.GetValue(), 3), plasmaPos, DI_TEXT_ALIGN_RIGHT);
        DrawString(mIndexFont, FormatNumber(mMaxPlasmaInterpolator.GetValue(), 3), mPlasmaPos, DI_TEXT_ALIGN_RIGHT);
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

            Vector2 itemPos = pos + parms.boxsize / 2;
            Vector2 textPos = pos + parms.boxsize - (1, 1 + parms.amountfont.mFont.GetHeight());

            let item = CPlayer.mo.InvSel;
            
            // Draw Inventory icon
            DrawInventoryIcon(item, itemPos, DI_ITEM_CENTER, CVar.GetCVar("fdhud_inviconalpha", CPlayer).GetFloat());
            if (item.Amount > 1)
            {
                DrawString(parms.amountfont, FormatNumber(item.Amount, 0, 5), textpos, DI_TEXT_ALIGN_RIGHT, parms.cr, parms.itemalpha);
            }
        }
    }

    
    // Returns the length of the given value, used for FormatNumber
    int GetFormatAmount(int value)
    {
        if (CVar.GetCVar("fdhud_centervalue", CPlayer).GetBool())
        {
            int length;
            while (value >= 1 && length < 3)
            {
                value /= 10;
                length++;
            }

            return length;
        }
        else
        {
            return 3;
        }
    }
}
