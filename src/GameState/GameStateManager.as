namespace GameState
{
	namespace State
	{
		bool bIsInEditor = false;
		bool bIsPlayInEditor = false;
		bool bDoesPlayerExist = false;
		bool bIsActuallyPlaying = false;
		bool bStartRunHandled = false;
		bool bRetireRunHandled = false;
		bool bIsFinishedHandled = false;
		uint32 NumRespawns = 0;
	}

	bool IsReadyToRenderRoute() { return State::bIsInEditor && !State::bIsPlayInEditor; }
	bool IsReadyToRecordRoute() { return State::bStartRunHandled; }

	CSmScriptPlayer@ GetScriptPlayer() 
	{
		if (!State::bDoesPlayerExist)
		{
			error("GameState: Cannot get ScriptPlayer");
			return null;
		}
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		auto player = cast<CSmPlayer>(playground.Players[0]);
		auto scriptPlayer = cast<CSmScriptPlayer>(player.ScriptAPI);
		return scriptPlayer;
	}

	void ResetRespawnCounter() 
	{
		if (!State::bDoesPlayerExist)
		{
			State::NumRespawns = 0;
			return;
		}
		
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		if (playground.Arena is null || playground.Arena.Rules is null || playground.Arena.Rules.Scores.Length <= 0)
		{
			State::NumRespawns = 0;
		}
		else 
		{
			State::NumRespawns = playground.Arena.Rules.Scores[0].NbRespawnsRequested;
		}
	}

	void Tick()
	{
		auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
		if (editor is null) 
		{
			if (State::bIsInEditor) { GameState::OnEditorLeave(); }
			State::bIsInEditor = false;
			State::bIsPlayInEditor = false;
		}
		else 
		{
			if (!State::bIsInEditor) { GameState::OnEditorEnter(); }
			State::bIsInEditor = true;
		}

		if (!State::bIsInEditor) { return; }

		// ---------------------------------------------------------------
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		if (playground is null) 
		{
			if (State::bIsPlayInEditor) { GameState::OnPlayInEditorLeave(); }
			State::bIsPlayInEditor = false;
			State::bDoesPlayerExist = false;
		}
		else
		{
			if (!State::bIsPlayInEditor) { GameState::OnPlayInEditorEnter(); }
			State::bIsPlayInEditor = true;
			State::bDoesPlayerExist = playground.Players.Length > 0;
		}

		// ---------------------------------------------------------------
		if (State::bDoesPlayerExist)
		{
			auto player = cast<CSmPlayer>(playground.Players[0]);
			auto scriptPlayer = cast<CSmScriptPlayer>(player.ScriptAPI);
			
			State::bIsActuallyPlaying = 
				scriptPlayer.IsEntityStateAvailable &&
				player.CurrentLaunchedRespawnLandmarkIndex != NumericLimits::UINT32_MAX;
		}
		else 
		{
			State::bIsActuallyPlaying = false;
		}

		// ---------------------------------------------------------------
		if (State::bIsActuallyPlaying)
		{
			auto scriptPlayer = GetScriptPlayer();

			// Start / Retire Triggers
			{
				auto post = scriptPlayer.Post;
				if(post == CSmScriptPlayer::EPost::Char) 
				{
					if (!State::bRetireRunHandled) { GameState::OnRetireRun(); }
					State::bRetireRunHandled = true;
					State::bStartRunHandled = false;
				} 
				else if(post == CSmScriptPlayer::EPost::CarDriver) 
				{
					if (!State::bStartRunHandled) { GameState::OnStartRun(); }
					State::bStartRunHandled = true;
					State::bRetireRunHandled = false;
				}
			}

			// Finish Triggers
			if (playground.GameTerminals.Length > 0)
			{
				auto terminal = playground.GameTerminals[0];
				auto uiSequence = terminal.UISequence_Current;

				if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish) 
				{
					if (!State::bIsFinishedHandled) { GameState::OnFinishRun(); }
					State::bIsFinishedHandled = true;
				}
				else 
				{
					State::bIsFinishedHandled = false;
				}
			}

			// Respawn Triggers
			if (playground.Arena !is null && playground.Arena.Rules !is null && playground.Arena.Rules.Scores.Length > 0)
			{
				
				uint32 newNumRespawns = playground.Arena.Rules.Scores[0].NbRespawnsRequested;
				if (newNumRespawns > State::NumRespawns)
				{
					GameState::OnRespawnRun();
					State::NumRespawns = newNumRespawns;
				}
				else if (newNumRespawns < State::NumRespawns)
				{
					trace("Respawn Counter missed an update.");
					State::NumRespawns = newNumRespawns;
				}
			}
		}
		else 
		{
			State::bStartRunHandled = false;
			State::bRetireRunHandled = false;
			State::bIsFinishedHandled = false;
			State::NumRespawns = 0;
		}
	}
}