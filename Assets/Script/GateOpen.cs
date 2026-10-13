using UnityEngine;

/// <summary>
/// Gắn vào một object rỗng có BoxCollider (Is Trigger) đặt trước thanh rào.
/// Người chơi đứng trong vùng trigger, có đủ vật phẩm yêu cầu và nhấn E thì thanh rào nâng lên.
/// Rời khỏi vùng thì rào tự hạ xuống sau vài giây.
/// </summary>
[RequireComponent(typeof(Collider))]
public class BarrierGate : MonoBehaviour
{
    [Header("Vật phẩm yêu cầu")]
    public bool requireItem = true;
    public string requiredItemId = "GateKey";
    public int requiredAmount = 1;
    [Tooltip("Bật nếu muốn mở xong thì mất vật phẩm")]
    public bool consumeItem = false;

    [Header("Thanh rào")]
    [Tooltip("Object xoay quanh bản lề (pivot đặt ở đầu gần chòi gác)")]
    public Transform arm;
    [Tooltip("Góc xoay khi mở. Thử Z = -80 hoặc 80, hoặc X nếu rào quay hướng khác")]
    public Vector3 openEulerOffset = new Vector3(0f, 0f, -80f);
    public float openSpeed = 90f; // độ / giây

    [Header("Điều khiển")]
    public bool autoOpen = false;
    public KeyCode interactKey = KeyCode.E;
    public float autoCloseDelay = 3f;

    [Header("Âm thanh (tùy chọn)")]
    public AudioSource audioSource;
    public AudioClip openSound;
    public AudioClip closeSound;
    public AudioClip deniedSound;

    private Quaternion closedRot;
    private Quaternion openRot;
    private bool isOpen;
    private bool playerInRange;
    private PlayerInventory inventory;
    private float closeTimer;
    private float deniedMessageTimer;

    private void Reset()
    {
        GetComponent<Collider>().isTrigger = true;
    }

    private void Start()
    {
        if (arm == null)
        {
            Debug.LogError("BarrierGate: chưa gán 'arm' (thanh rào)!", this);
            enabled = false;
            return;
        }

        closedRot = arm.localRotation;
        openRot = Quaternion.Euler(openEulerOffset) * closedRot;
    }

    private void Update()
    {
        if (playerInRange && !isOpen)
        {
            bool wantsOpen = autoOpen || Input.GetKeyDown(interactKey);
            if (wantsOpen) TryOpen();
        }

        if (isOpen && !playerInRange)
        {
            closeTimer -= Time.deltaTime;
            if (closeTimer <= 0f) Close();
        }

        if (deniedMessageTimer > 0f) deniedMessageTimer -= Time.deltaTime;

        Quaternion target = isOpen ? openRot : closedRot;
        arm.localRotation = Quaternion.RotateTowards(arm.localRotation, target, openSpeed * Time.deltaTime);
    }

    private bool HasRequiredItem()
    {
        if (!requireItem) return true;
        return inventory != null && inventory.Has(requiredItemId, requiredAmount);
    }

    private void TryOpen()
    {
        if (!HasRequiredItem())
        {
            deniedMessageTimer = 2f;
            Play(deniedSound);
            return;
        }

        if (requireItem && consumeItem) inventory.Remove(requiredItemId, requiredAmount);

        isOpen = true;
        Play(openSound);
    }

    private void Close()
    {
        isOpen = false;
        Play(closeSound);
    }

    private void Play(AudioClip clip)
    {
        if (audioSource != null && clip != null) audioSource.PlayOneShot(clip);
    }

    private void OnTriggerEnter(Collider other)
    {
        PlayerInventory inv = other.GetComponentInParent<PlayerInventory>();
        if (inv == null) return;

        inventory = inv;
        playerInRange = true;
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.GetComponentInParent<PlayerInventory>() == null) return;

        playerInRange = false;
        closeTimer = autoCloseDelay;
    }

    private void OnGUI()
    {
        if (!playerInRange || isOpen) return;

        string msg;
        if (deniedMessageTimer > 0f) msg = $"Cần {requiredAmount} x {requiredItemId} để mở rào!";
        else if (HasRequiredItem()) msg = autoOpen ? "" : $"Nhấn [{interactKey}] để mở rào";
        else msg = "Rào bị khóa";

        if (string.IsNullOrEmpty(msg)) return;

        var style = new GUIStyle(GUI.skin.label)
        {
            fontSize = 26,
            alignment = TextAnchor.MiddleCenter,
            fontStyle = FontStyle.Bold
        };
        style.normal.textColor = Color.white;

        GUI.Label(new Rect(0, Screen.height * 0.75f, Screen.width, 50), msg, style);
    }

    private void OnDrawGizmosSelected()
    {
        if (arm == null) return;
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(arm.position, 0.2f);
    }
}