﻿using Kermalis.EndianBinaryIO;
using Kermalis.PokemonBattleEngine.Data.Utils;
using Kermalis.PokemonBattleEngine.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Kermalis.PokemonBattleEngine.Data.Legality;

public sealed class PBELegalPokemonCollection : IPBEPokemonCollection, IPBEPokemonCollection<PBELegalPokemon>, INotifyCollectionChanged, INotifyPropertyChanged
{
	private void OnCollectionChanged(NotifyCollectionChangedEventArgs e)
	{
		CollectionChanged?.Invoke(this, e);
	}
	private void OnPropertyChanged(string property)
	{
		PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
	}
	public event NotifyCollectionChangedEventHandler? CollectionChanged;
	public event PropertyChangedEventHandler? PropertyChanged;

	private readonly List<PBELegalPokemon> _list;
	public int Count => _list.Count;
	public PBELegalPokemon this[int index]
	{
		get
		{
			if (index >= _list.Count)
			{
				throw new ArgumentOutOfRangeException(nameof(index));
			}
			return _list[index];
		}
		set => ReplaceAt(value, index);
	}
	IPBEPokemon IReadOnlyList<IPBEPokemon>.this[int index] => this[index];

	public PBESettings Settings { get; }

	internal PBELegalPokemonCollection(PBESettings settings, EndianBinaryReader r)
	{
		byte count = r.ReadByte();
		if (count < 1 || count > settings.MaxPartySize)
		{
			throw new InvalidDataException();
		}
		Settings = settings;
		_list = new List<PBELegalPokemon>(Settings.MaxPartySize);
		for (int i = 0; i < count; i++)
		{
			InsertWithEvents(false, new PBELegalPokemon(Settings, r), i);
		}
	}
	public PBELegalPokemonCollection(string path)
	{
		JsonObject jObj = JsonNode.Parse(File.ReadAllText(path))!.AsObject();

		Settings = new PBESettings(jObj.GetSafe(nameof(Settings)).GetValue<string>());
		Settings.MakeReadOnly();

		JsonArray jArray = jObj.GetSafe("Party").AsArray();
		if (jArray.Count < 1 || jArray.Count > Settings.MaxPartySize)
		{
			throw new InvalidDataException("Invalid party size.");
		}

		_list = new List<PBELegalPokemon>(Settings.MaxPartySize);
		for (int i = 0; i < jArray.Count; i++)
		{
			InsertWithEvents(false, new PBELegalPokemon(Settings, jArray.GetSafe(i).AsObject()), i);
		}
	}
	public PBELegalPokemonCollection(PBESettings settings)
	{
		settings.ShouldBeReadOnly(nameof(settings));
		Settings = settings;
		_list = new List<PBELegalPokemon>(Settings.MaxPartySize);
	}
	public PBELegalPokemonCollection(PBESettings settings, int numPkmnToGenerate, bool setToMaxLevel)
	{
		settings.ShouldBeReadOnly(nameof(settings));
		if (numPkmnToGenerate < 1 || numPkmnToGenerate > settings.MaxPartySize)
		{
			throw new ArgumentOutOfRangeException(nameof(numPkmnToGenerate));
		}
		Settings = settings;
		_list = new List<PBELegalPokemon>(Settings.MaxPartySize);
		for (int i = 0; i < numPkmnToGenerate; i++)
		{
			InsertRandom(setToMaxLevel, false, i);
		}
	}

	private void InsertRandom(bool setToMaxLevel, bool fireEvent, int index)
	{
		(PBESpecies species, PBEForm form) = PBEDataProvider.GlobalRandom.RandomSpecies(true);
		byte level = setToMaxLevel ? Settings.MaxLevel : PBEDataProvider.GlobalRandom.RandomLevel(Settings);
		Insert(species, form, level, PBEDataProvider.Instance.GetEXPRequired(PBEDataProvider.Instance.GetPokemonData(species, form).GrowthRate, level), fireEvent, index);
	}
	private void Insert(PBESpecies species, PBEForm form, byte level, uint exp, bool fireEvent, int index)
	{
		InsertWithEvents(fireEvent, new PBELegalPokemon(species, form, level, exp, Settings), index);
	}
	private void InsertWithEvents(bool fireEvent, PBELegalPokemon item, int index)
	{
		_list.Insert(index, item);
		if (fireEvent)
		{
			OnPropertyChanged(nameof(Count));
			OnPropertyChanged("Item[]");
			OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Add, item, index));
		}
	}
	private void RemoveWithEvents(PBELegalPokemon item, int index)
	{
		_list.RemoveAt(index);
		NotifyCollectionChangedEventArgs e;
		if (_list.Count == 0)
		{
			InsertRandom(false, false, 0);
			e = new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Replace, _list[0], item, 0);
		}
		else
		{
			OnPropertyChanged(nameof(Count));
			e = new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Remove, item, index);
		}
		OnPropertyChanged("Item[]");
		OnCollectionChanged(e);
	}

	private void ExceedException()
	{
		throw new InvalidOperationException($"Party size cannot exceed \"{nameof(Settings.MaxPartySize)}\" ({Settings.MaxPartySize}).");
	}
	public void AddRandom(bool setToMaxLevel)
	{
		if (_list.Count < Settings.MaxPartySize)
		{
			InsertRandom(setToMaxLevel, true, _list.Count);
		}
		else
		{
			ExceedException();
		}
	}
	public void Add(PBESpecies species, PBEForm form, byte level, uint exp)
	{
		PBEDataUtils.ValidateSpecies(species, form, true);
		PBEDataUtils.ValidateLevel(level, Settings);
		PBEDataUtils.ValidateEXP(PBEDataProvider.Instance.GetPokemonData(species, form).GrowthRate, exp, level);
		if (_list.Count < Settings.MaxPartySize)
		{
			Insert(species, form, level, exp, true, _list.Count);
		}
		else
		{
			ExceedException();
		}
	}
	public void Add(PBELegalPokemon item)
	{
		if (!Settings.Equals(item.Settings))
		{
			throw new ArgumentException("Settings must be equal.", nameof(item));
		}
		if (_list.Count < Settings.MaxPartySize)
		{
			InsertWithEvents(true, item, _list.Count);
		}
		else
		{
			ExceedException();
		}
	}
	public void InsertRandom(bool setToMaxLevel, int index)
	{
		if (_list.Count < Settings.MaxPartySize)
		{
			InsertRandom(setToMaxLevel, true, index);
		}
		else
		{
			ExceedException();
		}
	}
	public void Insert(PBESpecies species, PBEForm form, byte level, uint exp, int index)
	{
		PBEDataUtils.ValidateSpecies(species, form, true);
		PBEDataUtils.ValidateLevel(level, Settings);
		if (_list.Count < Settings.MaxPartySize)
		{
			Insert(species, form, level, exp, true, index);
		}
		else
		{
			ExceedException();
		}
	}
	public void Insert(PBELegalPokemon item, int index)
	{
		if (!Settings.Equals(item.Settings))
		{
			throw new ArgumentException("Settings must be equal.", nameof(item));
		}
		if (_list.Count < Settings.MaxPartySize)
		{
			InsertWithEvents(true, item, index);
		}
		else
		{
			ExceedException();
		}
	}
	public void Clear()
	{
		int oldCount = _list.Count;
		_list.Clear();
		InsertRandom(false, false, 0);
		if (oldCount != 1)
		{
			OnPropertyChanged(nameof(Count));
		}
		OnPropertyChanged("Item[]");
		OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
	}
	public bool Remove(PBELegalPokemon item)
	{
		int index = _list.IndexOf(item);
		bool b = index != -1;
		if (b)
		{
			RemoveWithEvents(item, index);
		}
		return b;
	}
	public void RemoveAt(int index)
	{
		if (index < 0 || index >= _list.Count)
		{
			throw new ArgumentOutOfRangeException(nameof(index));
		}
		else
		{
			RemoveWithEvents(_list[index], index);
		}
	}
	public void ReplaceAt(PBELegalPokemon item, int index)
	{
		if (index >= _list.Count)
		{
			throw new ArgumentOutOfRangeException(nameof(index));
		}
		if (!Settings.Equals(item.Settings))
		{
			throw new ArgumentException("Settings must be equal.", nameof(item));
		}
		PBELegalPokemon old = _list[index];
		_list[index] = item;
		OnPropertyChanged("Item[]");
		OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Replace, item, old, index));
	}

	public bool Contains(PBELegalPokemon item)
	{
		return _list.IndexOf(item) != -1;
	}
	public int IndexOf(PBELegalPokemon item)
	{
		return _list.IndexOf(item);
	}

	public IEnumerator<PBELegalPokemon> GetEnumerator()
	{
		return _list.GetEnumerator();
	}
	IEnumerator IEnumerable.GetEnumerator()
	{
		return _list.GetEnumerator();
	}
	IEnumerator<IPBEPokemon> IEnumerable<IPBEPokemon>.GetEnumerator()
	{
		return _list.GetEnumerator();
	}

	public void ToJsonFile(string path)
	{
		using (FileStream fs = File.OpenWrite(path))
		using (var w = new Utf8JsonWriter(fs, options: new JsonWriterOptions { Indented = true }))
		{
			w.WriteStartObject();

			w.WriteString(nameof(Settings), Settings.ToString());

			w.WriteStartArray("Party");
			for (int i = 0; i < _list.Count; i++)
			{
				_list[i].ToJson(w);
			}
			w.WriteEndArray();

			w.WriteEndObject();
		}
	}
}
