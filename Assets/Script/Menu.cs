using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;

public class MainMenuController : MonoBehaviour
{
    [Header("UI Panels")]
    [SerializeField] private GameObject menuPanel;
    [SerializeField] private GameObject mainHUDPanel;

    [Header("UI Buttons")]
    [SerializeField] private Button newGameBtn;
    [SerializeField] private Button loadGameBtn;
    [SerializeField] private Button quitBtn;

    [Header("Cameras & World")]
    [SerializeField] private GameObject menuCam;
    [SerializeField] private GameObject playerObj;

    [Header("Intro Video Setup")]
    [SerializeField] private VideoPlayer introVideoPlayer;
    [SerializeField] private RawImage videoRawImage;
    [SerializeField] private bool allowSkipVideo = true;

    [Header("Audio")]
    [SerializeField] private AudioSource ambientAudio;
    [SerializeField] private AudioSource buttonSFX;

    private bool isPlayingVideo = false;

    private void Start()
    {
        if (newGameBtn != null) newGameBtn.onClick.AddListener(OnNewGameClicked);
        if (loadGameBtn != null) loadGameBtn.onClick.AddListener(OnLoadGameClicked);
        if (quitBtn != null) quitBtn.onClick.AddListener(OnQuitClicked);

        if (menuPanel != null) menuPanel.SetActive(true);
        if (mainHUDPanel != null) mainHUDPanel.SetActive(false);
        if (videoRawImage != null) videoRawImage.enabled = false;

        if (menuCam != null) menuCam.SetActive(true);
        if (playerObj != null) playerObj.SetActive(false);

        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;

        if (ambientAudio != null && !ambientAudio.isPlaying)
            ambientAudio.Play();
    }

    private void Update()
    {
        if (isPlayingVideo && allowSkipVideo)
        {
            if (Input.GetKeyDown(KeyCode.Space)
             || Input.GetKeyDown(KeyCode.Escape)
             || Input.GetMouseButtonDown(0))
            {
                StopAllCoroutines();
                EndIntroVideo();
            }
        }
    }

    public void OnNewGameClicked()
    {
        PlaySound();

        if (introVideoPlayer != null)
            StartCoroutine(PlayVideoSequence());
        else
            StartGameDirectly();
    }

    private IEnumerator PlayVideoSequence()
    {
        isPlayingVideo = true;

        if (ambientAudio != null) ambientAudio.Stop();
        if (videoRawImage != null) videoRawImage.enabled = true;

        introVideoPlayer.Play();

        yield return null;
        yield return null;
        yield return null;

        float timeout = 5f;
        while (introVideoPlayer.length <= 0 && timeout > 0)
        {
            timeout -= Time.deltaTime;
            yield return null;
        }

        float videoDuration = (float)introVideoPlayer.length;
        Debug.Log($"[Menu] Video duration: {videoDuration}s");

        if (videoDuration > 0)
            yield return new WaitForSeconds(videoDuration);
        else
            Debug.LogWarning("[Menu] Không đọc được duration, bỏ qua video.");

        EndIntroVideo();
    }

    private void EndIntroVideo()
    {
        if (introVideoPlayer != null && introVideoPlayer.isPlaying)
            introVideoPlayer.Stop();

        if (videoRawImage != null) videoRawImage.enabled = false;
        if (menuPanel != null) menuPanel.SetActive(false);

        isPlayingVideo = false;

        // Gọi vào game sau khi video xong
        StartGameDirectly();
    }

    private void StartGameDirectly()
    {
        Debug.Log("[Menu] StartGameDirectly called");

        if (menuCam != null) menuCam.SetActive(false);
        if (playerObj != null) playerObj.SetActive(true);   // bật player
        if (mainHUDPanel != null) mainHUDPanel.SetActive(true); // bật HUD

        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;

        Debug.Log("[Menu] Game started!");
    }

    public void OnLoadGameClicked()
    {
        PlaySound();
        Debug.Log("Load Game Clicked!");
    }

    public void OnQuitClicked()
    {
        PlaySound();
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