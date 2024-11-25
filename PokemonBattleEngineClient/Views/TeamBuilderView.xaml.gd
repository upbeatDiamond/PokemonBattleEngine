﻿using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Kermalis.PokemonBattleEngine.Data;
using Kermalis.PokemonBattleEngine.Data.Legality;
using Kermalis.PokemonBattleEngineClient.Infrastructure;
using Kermalis.PokemonBattleEngineClient.Models;
using System;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.IO;

namespace Kermalis.PokemonBattleEngineClient.Views;

public sealed class TeamBuilderView : UserControl, INotifyPropertyChanged
{
	private void OnPropertyChanged(string property)
	{
		PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
	}
	public new event PropertyChangedEventHandler? PropertyChanged;

	private Uri _spriteUri;
	public Uri SpriteUri
	{
		get => _spriteUri;
		private set
		{
			if (_spriteUri != value)
			{
				_spriteUri = value;
				OnPropertyChanged(nameof(SpriteUri));
			}
		}
	}

	private PBELegalPokemon _pkmn;
	public PBELegalPokemon Pkmn
	{
		get => _pkmn;
		set
		{
			if (_pkmn != value)
			{
				PBELegalPokemon old = _pkmn;
				if (old is not null)
				{
					old.PropertyChanged -= OnPkmnPropertyChanged;
				}
				_pkmn = value;
				value.PropertyChanged += OnPkmnPropertyChanged;
				_ignoreComboBoxChanges = true;
				OnPropertyChanged(nameof(Pkmn));
				_partyListBox.SelectedItem = value;
				UpdateEXPRequirements();
				UpdateComboBoxes(null);
				_ignoreComboBoxChanges = false;
			}
		}
	}
	private uint _minEXP;
	public uint MinEXP
	{
		get => _minEXP;
		set
		{
			if (_minEXP != value)
			{
				_minEXP = value;
				OnPropertyChanged(nameof(MinEXP));
			}
		}
	}
	private uint _maxEXP;
	public uint MaxEXP
	{
		get => _maxEXP;
		set
		{
			if (_maxEXP != value)
			{
				_maxEXP = value;
				OnPropertyChanged(nameof(MaxEXP));
			}
		}
	}
	private TeamInfo _team;
	public TeamInfo Team
	{
		get => _team;
		set
		{
			if (_team != value)
			{
				_teamListBox.SelectedItem = value;
				_team = value;
				OnPropertyChanged(nameof(Team));
			}
		}
	}
	public ObservableCollection<TeamInfo> Teams { get; } = new();

	private readonly string _teamPath;
	private readonly Button _addPartyButton;
	private readonly Button _removePartyButton;
	// Avalonia selection is broken (as always) so I need to manually get the SelectedItem instead of using the bindings :))))))))))))))
	private readonly ListBox _partyListBox;
	private readonly ListBox _teamListBox;
	private bool _ignoreComboBoxChanges = false;
	private readonly ComboBox _abilityComboBox;
	private readonly ComboBox _formComboBox;
	private readonly ComboBox _genderComboBox;
	private readonly ComboBox _itemComboBox;
	private readonly ComboBox _speciesComboBox;

	private void UpdateEXPRequirements()
	{
		PBEGrowthRate type = PBEDataProvider.Instance.GetPokemonData(_pkmn).GrowthRate;
		MinEXP = PBEDataProvider.Instance.GetEXPRequired(type, _pkmn.Settings.MinLevel);
		MaxEXP = PBEDataProvider.Instance.GetEXPRequired(type, _pkmn.Settings.MaxLevel);
	}
	private void UpdateComboBoxes(string? property)
	{
		bool all = property is null;
		bool ability = all;
		bool form = all;
		bool gender = all;
		bool item = all;
		bool species = all;
		if (!all)
		{
			switch (property)
			{
				case nameof(PBELegalPokemon.Ability): ability = true; break;
				case nameof(PBELegalPokemon.Form): form = true; break;
				case nameof(PBELegalPokemon.Gender): gender = true; break;
				case nameof(PBELegalPokemon.Item): item = true; break;
				case nameof(PBELegalPokemon.Species): species = true; break;
			}
		}
		if (ability)
		{
			_abilityComboBox.SelectedItem = _pkmn.Ability;
		}
		if (form)
		{
			_formComboBox.SelectedItem = _pkmn.Form;
		}
		if (gender)
		{
			_genderComboBox.SelectedItem = _pkmn.Gender;
		}
		if (item)
		{
			_itemComboBox.SelectedItem = _pkmn.Item;
		}
		if (species)
		{
			_speciesComboBox.SelectedItem = _pkmn.Species;
		}
	}
	private void OnPkmnPropertyChanged(object? sender, PropertyChangedEventArgs e)
	{
		UpdateComboBoxes(e.PropertyName);
		if (e.PropertyName == nameof(PBELegalPokemon.Species) || e.PropertyName == nameof(PBELegalPokemon.Form))
		{
			UpdateEXPRequirements();
		}
	}
	private void OnComboBoxSelectionChanged(object? sender, SelectionChangedEventArgs thing)
	{
		if (_ignoreComboBoxChanges)
		{
			return;
		}

		_ignoreComboBoxChanges = true;
		var c = (ComboBox)sender!;
		if (c == _abilityComboBox)
		{
			_pkmn.Ability = (PBEAbility)c.SelectedItem!;
		}
		else if (c == _formComboBox)
		{
			_pkmn.Form = (PBEForm)c.SelectedItem!;
		}
		else if (c == _genderComboBox)
		{
			_pkmn.Gender = (PBEGender)c.SelectedItem!;
		}
		else if (c == _itemComboBox)
		{
			_pkmn.Item = (PBEItem)c.SelectedItem!;
		}
		else if (c == _speciesComboBox)
		{
			_pkmn.Species = (PBESpecies)c.SelectedItem!;
		}
		_ignoreComboBoxChanges = false;
	}

#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.
	public TeamBuilderView()
#pragma warning restore CS8618 // _team, _pkmn, _spriteUri
	{
		DataContext = this;
		AvaloniaXamlLoader.Load(this);

		_abilityComboBox = this.FindControl<ComboBox>("Ability");
		_abilityComboBox.SelectionChanged += OnComboBoxSelectionChanged;
		_formComboBox = this.FindControl<ComboBox>("Form");
		_formComboBox.SelectionChanged += OnComboBoxSelectionChanged;
		_formComboBox.SelectionChanged += OnVisualChanged;
		_genderComboBox = this.FindControl<ComboBox>("Gender");
		_genderComboBox.SelectionChanged += OnComboBoxSelectionChanged;
		_genderComboBox.SelectionChanged += OnVisualChanged;
		_itemComboBox = this.FindControl<ComboBox>("Item");
		_itemComboBox.SelectionChanged += OnComboBoxSelectionChanged;
		_speciesComboBox = this.FindControl<ComboBox>("Species");
		_speciesComboBox.SelectionChanged += OnComboBoxSelectionChanged;
		_speciesComboBox.SelectionChanged += OnVisualChanged;
		_teamListBox = this.FindControl<ListBox>("SavedTeams");
		_teamListBox.SelectionChanged += OnSelectedTeamChanged;
		_addPartyButton = this.FindControl<Button>("AddParty");
		_removePartyButton = this.FindControl<Button>("RemoveParty");
		_partyListBox = this.FindControl<ListBox>("Party");
		_partyListBox.SelectionChanged += OnSelectedMonChanged;

		_teamPath = Path.Combine(Utils.WorkingDirectory, "Teams");
		if (Directory.Exists(_teamPath))
		{
			string[] files = Directory.GetFiles(_teamPath);
			if (files.Length > 0)
			{
				for (int i = 0; i < files.Length; i++)
				{
					string file = files[i];
					var t = new TeamInfo(Path.GetFileNameWithoutExtension(file), new PBELegalPokemonCollection(file));
					Teams.Add(t);
					if (i == 0)
					{
						Team = t;
						Pkmn = t.Party[0];
					}
				}
				return;
			}
		}
		else
		{
			Directory.CreateDirectory(_teamPath);
		}
		AddTeam();
	}

	public void AddTeam()
	{
		var t = new TeamInfo($"Team {DateTime.Now.Ticks}", new PBELegalPokemonCollection(PBESettings.DefaultSettings, 1, true));
		Teams.Add(t);
		Team = t;
		Pkmn = t.Party[0];
	}
	public void RemoveTeam()
	{
		File.Delete(Path.Combine(_teamPath, $"{_team.Name}.json"));
		TeamInfo old = _team;
		if (Teams.Count == 1)
		{
			AddTeam();
		}
		Teams.Remove(old);
	}
	public void SaveTeam()
	{
		_team.Party.ToJsonFile(Path.Combine(_teamPath, $"{_team.Name}.json"));
	}
	// I love Avalonia :))))))))))
	// Using it for years and still has the same problems
	public void AddPartyMember()
	{
		int index = _team.Party.Count;
		_team.Party.AddRandom(true);
		_partyListBox.Items = null; // How is it so broken still
		_partyListBox.Items = _team.Party;
		Pkmn = _team.Party[index];
	}
	public void RemovePartyMember()
	{
		_team.Party.Remove(_pkmn);
		_partyListBox.Items = null;
		_partyListBox.Items = _team.Party;
		Pkmn = _team.Party[_team.Party.Count - 1];
	}
	private void OnSelectedMonChanged(object? sender, SelectionChangedEventArgs e)
	{
		var s = (PBELegalPokemon?)_partyListBox.SelectedItem;
		if (s is not null)
		{
			Pkmn = s;
		}
	}
	private void OnSelectedTeamSizeChanged(object? sender, NotifyCollectionChangedEventArgs? e)
	{
		_addPartyButton.IsEnabled = _team.Party.Count < _team.Party.Settings.MaxPartySize;
		_removePartyButton.IsEnabled = _team.Party.Count > 1;
	}
	private void OnSelectedTeamChanged(object? sender, SelectionChangedEventArgs e)
	{
		if (_team is not null)
		{
			_team.Party.CollectionChanged -= OnSelectedTeamSizeChanged;
		}
		_team = (TeamInfo)_teamListBox.SelectedItem!;
		_team.Party.CollectionChanged += OnSelectedTeamSizeChanged;
		_partyListBox.Items = _team.Party;
		OnSelectedTeamSizeChanged(null, null);
		Pkmn = _team.Party[0];
	}
	private void OnVisualChanged(object? sender, SelectionChangedEventArgs e)
	{
		UpdateSprites();
	}
	public void UpdateSprites()
	{
		SpriteUri = Utils.GetPokemonSpriteUri(_pkmn);
		// Force redraw of minisprite
		IControl c = _partyListBox.ItemContainerGenerator.ContainerFromIndex(_partyListBox.SelectedIndex);
		if (c is ListBoxItem item)
		{
			object old = item.Content;
			item.Content = null;
			item.Content = old;
		}
	}
}
