using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Gắn vào Player. Túi đồ chung: lưu mọi loại vật phẩm theo ID kèm số lượng.
/// </summary>
public class PlayerInventory : MonoBehaviour
{
    private readonly Dictionary<string, int> items = new Dictionary<string, int>();

    /// <summary>Gọi mỗi khi số lượng thay đổi: (itemId, số lượng mới). Dùng để cập nhật UI.</summary>
    public event Action<string, int> OnItemChanged;

    public int Count(string itemId)
    {
        return items.TryGetValue(itemId, out int c) ? c : 0;
    }

    public bool Has(string itemId, int amount = 1) => Count(itemId) >= amount;

    public void Add(string itemId, int amount = 1)
    {
        if (amount <= 0) return;
        items[itemId] = Count(itemId) + amount;
        OnItemChanged?.Invoke(itemId, items[itemId]);
    }
    
    /// <summary>Trừ vật phẩm. Trả về false (và không trừ gì) nếu không đủ.</summary>
    public bool Remove(string itemId, int amount = 1)
    {
        if (!Has(itemId, amount)) return false;

        int left = Count(itemId) - amount;
        if (left <= 0) items.Remove(itemId);
        else items[itemId] = left;

        OnItemChanged?.Invoke(itemId, left);
        return true;
    }
}