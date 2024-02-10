namespace Fonts
{
    enum Type
    {
        DroidSans,
        DroidSansMono,
        DroidSansBold,
        NumFonts
    }
    
    namespace Private
    {
        int32[] NVG(int32(Type::NumFonts));
        UI::Font@[] UI(int32(Type::NumFonts));
    }

    void Load()
    {
        Private::NVG[Fonts::Type::DroidSans] = nvg::LoadFont("DroidSans.ttf", true);
        Private::NVG[Fonts::Type::DroidSansMono] = nvg::LoadFont("DroidSansMono.ttf", true);
        Private::NVG[Fonts::Type::DroidSansBold] = nvg::LoadFont("DroidSans-Bold.ttf", true);

        @Private::UI[Fonts::Type::DroidSans] = null; // Unused, activate if needed: UI::LoadFont("DroidSans-Bold.ttf", 16.f);
        @Private::UI[Fonts::Type::DroidSansMono] = null; // Unused, activate if needed: UI::LoadFont("DroidSans-Bold.ttf", 16.f);
        @Private::UI[Fonts::Type::DroidSansBold] = UI::LoadFont("DroidSans-Bold.ttf", 16.f);
    }

    int32 nvg(Fonts::Type font){ return Private::NVG[int32(font)];}
    UI::Font@ UI(Fonts::Type font){ return Private::UI[int32(font)];}
}