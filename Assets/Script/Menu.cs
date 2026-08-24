using UnityEngine;
using UnityEngine.UI; // Cần thiết để khai báo kiểu Button

public class MainMenuController : MonoBehaviour
{
    [Header("UI Panels")]
    [SerializeField] private GameObject menuPanel;     // GameObject 'Menu'
    [SerializeField] private GameObject mainHUDPanel;  // UI chính trong game (thanh máu, HUD...)

    [Header("UI Buttons")]
    [SerializeField] private Button newGameBtn;        // Drag 'Button' (New Game) vào đây
    [SerializeField] private Button loadGameBtn;       // Drag 'Button (2)' (Load Game) vào đây
    [SerializeField] private Button quitBtn;           // Drag 'Button (1)' (Quit) vào đây

    [Header("Cameras & World")]
    [SerializeField] private GameObject menuCam;       // GameObject 'Menu cam'
    [SerializeField] private GameObject playerObj;     // GameObject 'Player'

    [Header("Audio")]
    [SerializeField] private AudioSource ambientAudio; // GameObject 'ambient'
    [SerializeField] private AudioSource buttonSFX;    // Tiếng click nút (nếu có)

    private void Start()
    {
        // 1. Gán sự kiện cho các nút bằng Code (Không cần chỉnh On Click trong Inspector nữa)
        if (newGameBtn != null) newGameBtn.onClick.AddListener(OnNewGameClicked);
        if (loadGameBtn != null) loadGameBtn.onClick.AddListener(OnLoadGameClicked);
        if (quitBtn != null) quitBtn.onClick.AddListener(OnQuitClicked);

        // 2. Trạng thái ban đầu khi ở Menu
        if (menuPanel != null) menuPanel.SetActive(true);
        if (mainHUDPanel != null) mainHUDPanel.SetActive(false);

        if (menuCam != null) menuCam.SetActive(true);
        if (playerObj != null) playerObj.SetActive(false);

        // Bật chuột để bấm Menu
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;

        if (ambientAudio != null && !ambientAudio.isPlaying)
            ambientAudio.Play();
    }

    // --- CÁC HÀM XỬ LÝ LOGIC ---

    public void OnNewGameClicked()
    {
        PlaySound();

        // Tắt Menu & MenuCam, Bật HUD & Player
        if (menuPanel != null) menuPanel.SetActive(false);
        if (mainHUDPanel != null) mainHUDPanel.SetActive(true);

        if (menuCam != null) menuCam.SetActive(false);
        if (playerObj != null) playerObj.SetActive(true);

        // Khóa và ẩn chuột để xoay camera nhân vật
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    public void OnLoadGameClicked()
    {
        PlaySound();
        Debug.Log("Load Game Clicked!");
    }

    public void OnQuitClicked()
    {
        PlaySound();
        Debug.Log("Game Exiting...");

#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
    }

    private void PlaySound()
    {
        if (buttonSFX != null) buttonSFX.Play();
    }
}