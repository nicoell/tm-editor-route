namespace Fonts
{
    enum Type
    {
        DroidSans,
        DroidSansMono,
        DroidSansBold,
        NumFonts
    }
    
    namespace Internal
    {
        int32[] NVG(int32(Type::NumFonts));
        UI::Font@[] UI(int32(Type::NumFonts));
    }

    void Load()
    {
        Internal::NVG[Fonts::Type::DroidSans] = nvg::LoadFont("DroidSans.ttf", true);
        Internal::NVG[Fonts::Type::DroidSansMono] = nvg::LoadFont("DroidSansMono.ttf", true);
        Internal::NVG[Fonts::Type::DroidSansBold] = nvg::LoadFont("DroidSans-Bold.ttf", true);

        @Internal::UI[Fonts::Type::DroidSans] = null; // Unused, activate if needed: UI::LoadFont("DroidSans-Bold.ttf", 16.f);
        @Internal::UI[Fonts::Type::DroidSansMono] = null; // Unused, activate if needed: UI::LoadFont("DroidSans-Bold.ttf", 16.f);
        @Internal::UI[Fonts::Type::DroidSansBold] = UI::LoadFont("DroidSans-Bold.ttf", 16.f);
    }

    int32 nvg(Fonts::Type font){ return Internal::NVG[int32(font)];}
    UI::Font@ UI(Fonts::Type font){ return Internal::UI[int32(font)];}
}