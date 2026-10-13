using UnityEngine;

/// <summary>
/// Gắn vào bất kỳ vật phẩm nào nhặt được: chìa khóa, đạn, bình máu, tiền...
/// Cần có Collider (tự bật Is Trigger).
/// </summary>
[RequireComponent(typeof(Collider))]
public class ItemPickup : MonoBehaviour
{
    [Header("Vật phẩm")]
    [Tooltip("Ví dụ: GateKey, Ammo, HealthPotion, Coin")]
    public string itemId = "GateKey";
    public int amount = 1;

    [Header("Cách nhặt")]
    [Tooltip("Bật: chạm là nhặt. Tắt: đứng gần rồi nhấn phím để nhặt")]
    public bool autoPickup = true;
    public KeyCode pickupKey = KeyCode.E;

    [Header("Hiệu ứng")]
    public bool spin = true;
    public float rotateSpeed = 90f;
    public float bobHeight = 0.15f;
    public float bobSpeed = 2f;
    public AudioClip pickupSound;

    private Vector3 startPos;
    private PlayerInventory playerInRange;

    private void Reset()
    {
        GetComponent<Collider>().isTrigger = true;
    }

    private void Start()
    {
        startPos = transform.position;
    }

    private void Update()
    {
        if (spin)
        {
            transform.Rotate(Vector3.up, rotateSpeed * Time.deltaTime, Space.World);
            transform.position = startPos + Vector3.up * (Mathf.Sin(Time.time * bobSpeed) * bobHeight);
        }

        if (!autoPickup && playerInRange != null && Input.GetKeyDown(pickupKey))
            Collect(playerInRange);
    }

    private void OnTriggerEnter(Collider other)
    {
        PlayerInventory inv = other.GetComponentInParent<PlayerInventory>();
        if (inv == null) return;

        if (autoPickup) Collect(inv);
        else playerInRange = inv;
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.GetComponentInParent<PlayerInventory>() != null)
            playerInRange = null;
    }

    private void Collect(PlayerInventory inv)
    {
        inv.Add(itemId, amount);

        if (pickupSound != null)
            AudioSource.PlayClipAtPoint(pickupSound, transform.position);

        Debug.Log($"Đã nhặt {amount} x {itemId} (đang có: {inv.Count(itemId)})");
        Destroy(gameObject);
    }

    private void OnGUI()
    {
        if (autoPickup || playerInRange == null) return;

        var style = new GUIStyle(GUI.skin.label)
        {
            fontSize = 24,
            alignment = TextAnchor.MiddleCenter,
            fontStyle = FontStyle.Bold
        };
        style.normal.textColor = Color.white;

        GUI.Label(new Rect(0, Screen.height * 0.8f, Screen.width, 40), $"Nhấn [{pickupKey}] để nhặt {itemId}", style);
    }
}