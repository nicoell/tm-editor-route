namespace Strings
{
#if ER_DEBUG
const string BuildModeSuffix = "_DEV";
#else
const string BuildModeSuffix = "";
#endif

const string MenuTitle = "\\$0A6" + Icons::Map + "\\$z Editor Route" + BuildModeSuffix;
const string WindowTitle = Icons::MapO + " Editor Route" + BuildModeSuffix;

}