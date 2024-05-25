namespace AsyncJson
{
/** Context for AsyncJson::WriteTask. */
class FTaskContext
{
	FTaskContext(Json::Value& value, TaskCallback@ callbackHandle, ref@ userData = null, const uint32 yieldTimeoutMs = 5) 
	{ 
		@Value = value; 
		@Callback = callbackHandle;
		@UserData = userData;
		YieldTimeoutMs = yieldTimeoutMs;
	}
	// Json value to write
	Json::Value@ Value = null;
	// Callback function handle to call
	TaskCallback@ Callback = null;
	// Optional userdata that is forwarded to FTaskResult
	ref@ UserData = null;
	
	// Timeout in milliseconds for AsyncJson to yield execution
	uint32 YieldTimeoutMs = 5;
};

/** JsonString from WriteTask. */
class FTaskResult
{
	// Json String result of Json::Write
	string JsonString;
	// Optional userdata that was provided with FTaskContext
	ref@ UserData = null;
};

funcdef void TaskCallback(FTaskResult@);

/** 
 Yieldable WriteTask function to be called via startnew or from an existing couroutine context 
 - Returns and prints error if argument is not of type FTaskContext or no Callback function handle was set
 - TaskCallback is called with a handle to FTaskResult that:
	- is null: if no Json::Value was provided to write
	- contains the string of the Json::Value
*/
void WriteTask(ref@ _arg)
{
	auto taskCtx = cast<FTaskContext@>(_arg);
	if (taskCtx is null )
	{
		error("AsyncJson WriteTask received invalid FTaskContext.");
		return;
	};
	if (taskCtx.Callback is null)
	{
		error("AsyncJson WriteTask received Callback that is null.");
		return;
	};

	if (taskCtx.Value is null)
	{
		taskCtx.Callback(null);
	}

	FTaskResult result;
	@result.UserData = taskCtx.UserData;
	result.JsonString = Private::Write(taskCtx.Value, taskCtx.YieldTimeoutMs);

	taskCtx.Callback(result);
}

namespace Private
{
	enum ENodeType
	{
		CloseObject,
		CloseArray,
		KeyValuePair
	}

	class FNodeState
	{
		string Key;
		const Json::Value@ Value = null;
		ENodeType NodeType;
		bool bProduceComma = false;

		FNodeState(const Json::Value@ value, bool produceComma)
		{
			Key = "";
			@Value = value;
			NodeType = ENodeType::KeyValuePair;
			bProduceComma = produceComma;
		}
		FNodeState(const string&in key, const Json::Value@ value, bool produceComma)
		{
			Key = key;
			@Value = value;
			NodeType = ENodeType::KeyValuePair;
			bProduceComma = produceComma;
		}
		FNodeState(ENodeType nodeType, bool produceComma = false)
		{
			Key = "";
			@Value = null;
			NodeType = nodeType;
			bProduceComma = produceComma;
		}
	}

	string Write(const Json::Value@ value, uint32 yieldTimeoutMs = 5)
	{
		string result = "";
		array<FNodeState@> stack;
		stack.InsertLast(FNodeState(value, false));

		uint32 lastYield = Time::Now;

		while(!stack.IsEmpty())
		{
			const FNodeState@ current = stack[stack.Length - 1];
			stack.RemoveLast();

			switch(current.NodeType)
			{
				case ENodeType::CloseObject:
				{
					result += "}";
					break;
				}
				case ENodeType::CloseArray:
				{
					result += "]";
					break;
				}
				case ENodeType::KeyValuePair:
				{
					if (current.bProduceComma) 
					{
						result += ',';
					}
					if (current.Key.Length != 0) 
					{
						result += '"' + current.Key + '":';
					}

					switch(current.Value.GetType())
					{
						case Json::Type::Object:
						{
							result += "{";
							stack.InsertLast(FNodeState(ENodeType::CloseObject));

							auto keys = current.Value.GetKeys();
							const uint32 numElements = keys.Length;
							for (uint32 i = 0; i < keys.Length; ++i) 
							{
								uint32 iEnd = numElements - 1 - i;
								stack.InsertLast(FNodeState(keys[iEnd], current.Value[keys[iEnd]], iEnd != 0));
							}
							break;
						}
						case Json::Type::Array:
						{
							result += "[";
							stack.InsertLast(FNodeState(ENodeType::CloseArray));

							const uint32 numElements = current.Value.Length;
							for (uint32 i = 0; i < numElements; ++i) 
							{
								uint32 iEnd = numElements - 1 - i;
								stack.InsertLast(FNodeState(current.Value[iEnd], iEnd != 0));
							}
							break;
						}
						default:
						{
							result += Json::Write(current.Value);
						}
					}
				}
			}

			if (Time::Now - lastYield > yieldTimeoutMs)
			{
				yield();
				lastYield = Time::Now;
			}
		}

		return result;
	}
}
}