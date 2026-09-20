
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;
using TMPro;

public class MainMenuController : MonoBehaviour
{
    // =========================================================
    // MAIN MENU
    // =========================================================

    [Header("MAIN MENU")]
    [SerializeField] private GameObject menuPanel;


    // =========================================================
    // MAIN UI CỦA PLAYER
    // =========================================================

    [Header("MAIN UI - PLAYER HUD")]
    [SerializeField] private GameObject mainUI;


    // =========================================================
    // BUTTONS
    // =========================================================

    [Header("MENU BUTTONS")]
    [SerializeField] private Button newGameBtn;
    [SerializeField] private Button loadGameBtn;
    [SerializeField] private Button quitBtn;


    // =========================================================
    // TEXT PLAY / RESUME
    // =========================================================

    [Header("PLAY / RESUME TEXT")]
    [SerializeField] private TMP_Text newGameButtonText;


    // =========================================================
    // TEXT LOAD / SAVE
    // =========================================================

    [Header("LOAD / SAVE TEXT")]
    [SerializeField] private TMP_Text loadGameButtonText;


    // =========================================================
    // INTRO VIDEO
    // =========================================================

    [Header("INTRO VIDEO")]
    [SerializeField] private VideoPlayer introVideoPlayer;

    [SerializeField] private RawImage videoRawImage;

    [SerializeField] private bool allowSkipVideo = true;


    // =========================================================
    // AUDIO
    // =========================================================

    [Header("BUTTON SOUND")]
    [SerializeField] private AudioSource buttonSFX;


    [Header("GAMEPLAY AUDIO")]
    [SerializeField] private AudioSource ambientAudio;


    [Header("MENU AUDIO")]
    [SerializeField] private AudioSource computerNoiseAudio;


    // =========================================================
    // PLAYER
    // =========================================================

    [Header("PLAYER")]
    [SerializeField] private Transform player;


    // =========================================================
    // STATE
    // =========================================================

    private bool isPlayingVideo = false;

    private bool hasStartedGame = false;

    private bool isMenuOpen = true;

    private Coroutine videoCoroutine;


    // =========================================================
    // START
    // =========================================================

    private void Start()
    {
        // -----------------------------------------------------
        // BUTTON EVENTS
        // -----------------------------------------------------

        if (newGameBtn != null)
            newGameBtn.onClick.AddListener(OnNewGameClicked);

        if (loadGameBtn != null)
            loadGameBtn.onClick.AddListener(OnLoadGameClicked);

        if (quitBtn != null)
            quitBtn.onClick.AddListener(OnQuitClicked);


        // -----------------------------------------------------
        // GAME STATE
        // -----------------------------------------------------

        hasStartedGame = false;

        isMenuOpen = true;

        isPlayingVideo = false;


        // -----------------------------------------------------
        // BAN ĐẦU:
        //
        // MAIN MENU = ON
        // MAIN UI   = OFF
        // -----------------------------------------------------

        if (menuPanel != null)
            menuPanel.SetActive(true);

        if (mainUI != null)
            mainUI.SetActive(false);


        // -----------------------------------------------------
        // VIDEO = OFF
        // -----------------------------------------------------

        if (videoRawImage != null)
            videoRawImage.gameObject.SetActive(false);


        // -----------------------------------------------------
        // VIDEO PLAYER
        // -----------------------------------------------------

        if (introVideoPlayer != null)
        {
            introVideoPlayer.playOnAwake = false;

            introVideoPlayer.isLooping = false;

            introVideoPlayer.Stop();


            if (introVideoPlayer.renderMode ==
                VideoRenderMode.RenderTexture)
            {
                if (introVideoPlayer.targetTexture != null &&
                    videoRawImage != null)
                {
                    videoRawImage.texture =
                        introVideoPlayer.targetTexture;
                }
            }
        }


        // -----------------------------------------------------
        // TEXT BAN ĐẦU
        // -----------------------------------------------------

        SetPlayButtonText("PLAY");

        SetLoadButtonText("LOAD GAME");


        // -----------------------------------------------------
        // MENU AUDIO
        // -----------------------------------------------------

        SetMenuAudio(true);


        // -----------------------------------------------------
        // CURSOR
        // -----------------------------------------------------

        Cursor.lockState = CursorLockMode.None;

        Cursor.visible = true;
    }


    // =========================================================
    // UPDATE
    // =========================================================

    private void Update()
    {
        // -----------------------------------------------------
        // ESC SKIP VIDEO
        // -----------------------------------------------------

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (isPlayingVideo && allowSkipVideo)
            {
                SkipIntroVideo();

                return;
            }
        }


        // -----------------------------------------------------
        // E = OPEN / CLOSE MENU
        // -----------------------------------------------------

        if (Input.GetKeyDown(KeyCode.E))
        {
            // Video đang chạy
            if (isPlayingVideo)
                return;


            // Chưa vào game
            if (!hasStartedGame)
                return;


            ToggleMenu();
        }


        // -----------------------------------------------------
        // SPACE / LEFT CLICK = SKIP VIDEO
        // -----------------------------------------------------

        if (isPlayingVideo && allowSkipVideo)
        {
            if (Input.GetKeyDown(KeyCode.Space) ||
                Input.GetMouseButtonDown(0))
            {
                SkipIntroVideo();
            }
        }
    }


    // =========================================================
    // PLAY / RESUME
    // =========================================================

    public void OnNewGameClicked()
    {
        if (isPlayingVideo)
            return;


        PlaySound();


        // -----------------------------------------------------
        // NẾU ĐÃ VÀO GAME
        //
        // PLAY -> RESUME
        // -----------------------------------------------------

        if (hasStartedGame)
        {
            Debug.Log("[Menu] RESUME GAME");

            CloseMenu();

            return;
        }


        // -----------------------------------------------------
        // KIỂM TRA VIDEO
        // -----------------------------------------------------

        bool hasVideoSource =
            introVideoPlayer != null &&
            (
                introVideoPlayer.clip != null ||
                !string.IsNullOrEmpty(introVideoPlayer.url)
            );


        // -----------------------------------------------------
        // CÓ VIDEO
        // -----------------------------------------------------

        if (hasVideoSource)
        {
            // Menu phải đang hiện
            if (menuPanel != null)
                menuPanel.SetActive(true);


            // Main UI vẫn tắt
            if (mainUI != null)
                mainUI.SetActive(false);


            if (videoCoroutine != null)
                StopCoroutine(videoCoroutine);


            videoCoroutine =
                StartCoroutine(PlayVideoSequence());
        }
        else
        {
            StartGame();
        }
    }


    // =========================================================
    // VIDEO
    // =========================================================

    private IEnumerator PlayVideoSequence()
    {
        isPlayingVideo = true;


        // Khóa button
        SetMenuButtonsInteractable(false);


        // Hiện video
        if (videoRawImage != null)
            videoRawImage.gameObject.SetActive(true);


        // Menu audio
        SetMenuAudio(true);


        // Reset video
        introVideoPlayer.Stop();

        introVideoPlayer.isLooping = false;


        // -----------------------------------------------------
        // PREPARE
        // -----------------------------------------------------

        introVideoPlayer.Prepare();


        float prepareTimeout = 10f;


        while (!introVideoPlayer.isPrepared &&
               prepareTimeout > 0f)
        {
            prepareTimeout -= Time.deltaTime;

            yield return null;
        }


        if (!introVideoPlayer.isPrepared)
        {
            Debug.LogWarning(
                "[Menu] Video Prepare thất bại!"
            );


            EndIntroVideo();

            yield break;
        }


        Debug.Log("[Menu] Video đã Prepare.");


        // -----------------------------------------------------
        // PLAY
        // -----------------------------------------------------

        introVideoPlayer.Play();


        float playTimeout = 3f;


        while (!introVideoPlayer.isPlaying &&
               playTimeout > 0f)
        {
            playTimeout -= Time.deltaTime;

            yield return null;
        }


        if (!introVideoPlayer.isPlaying)
        {
            Debug.LogWarning(
                "[Menu] Video không thể phát!"
            );


            EndIntroVideo();

            yield break;
        }


        Debug.Log("[Menu] Intro đang phát...");


        // -----------------------------------------------------
        // CHỜ VIDEO XONG
        // -----------------------------------------------------

        while (introVideoPlayer.isPlaying)
        {
            yield return null;
        }


        Debug.Log("[Menu] Intro đã phát xong!");


        EndIntroVideo();
    }


    // =========================================================
    // SKIP VIDEO
    // =========================================================

    private void SkipIntroVideo()
    {
        if (!isPlayingVideo)
            return;


        Debug.Log("[Menu] Skip Intro");


        if (videoCoroutine != null)
        {
            StopCoroutine(videoCoroutine);

            videoCoroutine = null;
        }


        EndIntroVideo();
    }


    // =========================================================
    // END VIDEO
    // =========================================================

    private void EndIntroVideo()
    {
        if (!isPlayingVideo)
            return;


        isPlayingVideo = false;


        // Stop video
        if (introVideoPlayer != null)
            introVideoPlayer.Stop();


        // Tắt RawImage video
        if (videoRawImage != null)
            videoRawImage.gameObject.SetActive(false);


        // Mở lại button
        SetMenuButtonsInteractable(true);


        // Bắt đầu gameplay
        StartGame();
    }


    // =========================================================
    // START GAME
    // =========================================================

    private void StartGame()
    {
        if (hasStartedGame)
            return;


        hasStartedGame = true;

        isMenuOpen = false;


        Debug.Log("[Menu] GAME STARTED");


        // -----------------------------------------------------
        // ĐỔI BUTTON TEXT
        // -----------------------------------------------------

        SetPlayButtonText("RESUME");

        SetLoadButtonText("SAVE GAME");


        // -----------------------------------------------------
        // MAIN MENU OFF
        // -----------------------------------------------------

        if (menuPanel != null)
            menuPanel.SetActive(false);


        // -----------------------------------------------------
        // MAIN UI ON
        // -----------------------------------------------------

        if (mainUI != null)
            mainUI.SetActive(true);


        // -----------------------------------------------------
        // GAMEPLAY AUDIO
        // -----------------------------------------------------

        SetMenuAudio(false);


        // -----------------------------------------------------
        // CURSOR
        // -----------------------------------------------------

        Cursor.lockState = CursorLockMode.Locked;

        Cursor.visible = false;
    }


    // =========================================================
    // TOGGLE MENU
    // =========================================================

    private void ToggleMenu()
    {
        if (isPlayingVideo)
            return;


        if (menuPanel == null)
            return;


        if (menuPanel.activeSelf)
        {
            CloseMenu();
        }
        else
        {
            OpenMenu();
        }
    }


    // =========================================================
    // OPEN MENU
    // =========================================================

    private void OpenMenu()
    {
        if (isPlayingVideo)
            return;


        isMenuOpen = true;


        Debug.Log("[Menu] MENU OPEN");


        // -----------------------------------------------------
        // MAIN MENU ON
        // -----------------------------------------------------

        menuPanel.SetActive(true);


        // -----------------------------------------------------
        // MAIN UI OFF
        // -----------------------------------------------------

        if (mainUI != null)
            mainUI.SetActive(false);


        // -----------------------------------------------------
        // AUDIO
        // -----------------------------------------------------

        SetMenuAudio(true);


        // -----------------------------------------------------
        // CURSOR
        // -----------------------------------------------------

        Cursor.lockState = CursorLockMode.None;

        Cursor.visible = true;
    }


    // =========================================================
    // CLOSE MENU
    // =========================================================

    private void CloseMenu()
    {
        isMenuOpen = false;


        Debug.Log("[Menu] MENU CLOSE");


        // -----------------------------------------------------
        // MAIN MENU OFF
        // -----------------------------------------------------

        if (menuPanel != null)
            menuPanel.SetActive(false);


        // -----------------------------------------------------
        // MAIN UI ON
        // -----------------------------------------------------

        if (mainUI != null)
            mainUI.SetActive(true);


        // -----------------------------------------------------
        // AUDIO
        // -----------------------------------------------------

        SetMenuAudio(false);


        // -----------------------------------------------------
        // CURSOR
        // -----------------------------------------------------

        Cursor.lockState = CursorLockMode.Locked;

        Cursor.visible = false;
    }


    // =========================================================
    // AUDIO
    // =========================================================

    private void SetMenuAudio(bool menuActive)
    {
        if (menuActive)
        {
            // -------------------------------------------------
            // MENU
            // -------------------------------------------------

            // Ambient OFF
            if (ambientAudio != null)
                ambientAudio.Stop();


            // Computer Noise ON
            if (computerNoiseAudio != null)
            {
                computerNoiseAudio.loop = true;


                if (!computerNoiseAudio.isPlaying)
                    computerNoiseAudio.Play();
            }
        }
        else
        {
            // -------------------------------------------------
            // GAMEPLAY
            // -------------------------------------------------

            // Computer Noise OFF
            if (computerNoiseAudio != null)
                computerNoiseAudio.Stop();


            // Ambient ON
            if (ambientAudio != null)
            {
                ambientAudio.loop = true;


                if (!ambientAudio.isPlaying)
                    ambientAudio.Play();
            }
        }
    }


    // =========================================================
    // BUTTON INTERACTABLE
    // =========================================================

    private void SetMenuButtonsInteractable(bool interactable)
    {
        if (newGameBtn != null)
            newGameBtn.interactable = interactable;


        if (loadGameBtn != null)
            loadGameBtn.interactable = interactable;


        if (quitBtn != null)
            quitBtn.interactable = interactable;
    }


    // =========================================================
    // LOAD / SAVE BUTTON
    // =========================================================

    public void OnLoadGameClicked()
    {
        if (isPlayingVideo)
            return;


        PlaySound();


        // -----------------------------------------------------
        // ĐÃ VÀO GAME
        //
        // LOAD GAME -> SAVE GAME
        // -----------------------------------------------------

        if (hasStartedGame)
        {
            SaveGame();

            return;
        }


        // -----------------------------------------------------
        // CHƯA VÀO GAME
        //
        // LOAD GAME
        // -----------------------------------------------------

        if (!HasSaveGame())
        {
            Debug.Log(
                "[Load] Không tìm thấy save game."
            );

            return;
        }


        LoadGame();
    }


    // =========================================================
    // SAVE GAME
    // =========================================================

    public void SaveGame()
    {
        if (player == null)
        {
            Debug.LogWarning(
                "[Save] Chưa gán Player!"
            );

            return;
        }


        // -----------------------------------------------------
        // POSITION
        // -----------------------------------------------------

        PlayerPrefs.SetFloat(
            "PlayerPosX",
            player.position.x
        );

        PlayerPrefs.SetFloat(
            "PlayerPosY",
            player.position.y
        );

        PlayerPrefs.SetFloat(
            "PlayerPosZ",
            player.position.z
        );


        // -----------------------------------------------------
        // ROTATION
        // -----------------------------------------------------

        PlayerPrefs.SetFloat(
            "PlayerRotX",
            player.eulerAngles.x
        );

        PlayerPrefs.SetFloat(
            "PlayerRotY",
            player.eulerAngles.y
        );

        PlayerPrefs.SetFloat(
            "PlayerRotZ",
            player.eulerAngles.z
        );


        // Save exists
        PlayerPrefs.SetInt(
            "HasSave",
            1
        );


        PlayerPrefs.Save();


        Debug.Log("[Save] Game Saved!");
    }


    // =========================================================
    // CHECK SAVE
    // =========================================================

    private bool HasSaveGame()
    {
        return PlayerPrefs.GetInt(
            "HasSave",
            0
        ) == 1;
    }


    // =========================================================
    // LOAD GAME
    // =========================================================

    public void LoadGame()
    {
        if (player == null)
        {
            Debug.LogWarning(
                "[Load] Chưa gán Player!"
            );

            return;
        }


        // -----------------------------------------------------
        // POSITION
        // -----------------------------------------------------

        float x =
            PlayerPrefs.GetFloat("PlayerPosX");

        float y =
            PlayerPrefs.GetFloat("PlayerPosY");

        float z =
            PlayerPrefs.GetFloat("PlayerPosZ");


        player.position =
            new Vector3(x, y, z);


        // -----------------------------------------------------
        // ROTATION
        // -----------------------------------------------------

        float rotX =
            PlayerPrefs.GetFloat("PlayerRotX");

        float rotY =
            PlayerPrefs.GetFloat("PlayerRotY");

        float rotZ =
            PlayerPrefs.GetFloat("PlayerRotZ");


        player.eulerAngles =
            new Vector3(
                rotX,
                rotY,
                rotZ
            );


        // -----------------------------------------------------
        // GAME STATE
        // -----------------------------------------------------

        hasStartedGame = true;

        isMenuOpen = false;


        // -----------------------------------------------------
        // BUTTON TEXT
        // -----------------------------------------------------

        SetPlayButtonText("RESUME");

        SetLoadButtonText("SAVE GAME");


        // -----------------------------------------------------
        // MAIN MENU OFF
        // -----------------------------------------------------

        if (menuPanel != null)
            menuPanel.SetActive(false);


        // -----------------------------------------------------
        // MAIN UI ON
        // -----------------------------------------------------

        if (mainUI != null)
            mainUI.SetActive(true);


        // -----------------------------------------------------
        // AUDIO
        // -----------------------------------------------------

        SetMenuAudio(false);


        // -----------------------------------------------------
        // CURSOR
        // -----------------------------------------------------

        Cursor.lockState = CursorLockMode.Locked;

        Cursor.visible = false;


        Debug.Log("[Load] Game Loaded!");
    }


    // =========================================================
    // TEXT
    // =========================================================

    private void SetPlayButtonText(string text)
    {
        if (newGameButtonText != null)
            newGameButtonText.text = text;
    }


    private void SetLoadButtonText(string text)
    {
        if (loadGameButtonText != null)
            loadGameButtonText.text = text;
    }


    // =========================================================
    // QUIT
    // =========================================================

    public void OnQuitClicked()
    {
        PlaySound();


        // Auto Save
        if (hasStartedGame && player != null)
        {
            SaveGame();
        }


#if UNITY_EDITOR

        UnityEditor.EditorApplication.isPlaying = false;

#else

        Application.Quit();

#endif
    }


    // =========================================================
    // BUTTON SOUND
    // =========================================================

    private void PlaySound()
    {
        if (buttonSFX != null)
            buttonSFX.Play();
    }


    // =========================================================
    // DESTROY
    // =========================================================

    private void OnDestroy()
    {
        if (newGameBtn != null)
            newGameBtn.onClick.RemoveListener(
                OnNewGameClicked
            );


        if (loadGameBtn != null)
            loadGameBtn.onClick.RemoveListener(
                OnLoadGameClicked
            );


        if (quitBtn != null)
            quitBtn.onClick.RemoveListener(
                OnQuitClicked
            );
    }
}
