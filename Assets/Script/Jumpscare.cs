using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class JumpScare : MonoBehaviour
{
    public enum ScareType
    {
        AudioOnly,
        UIImage,
        Object3D,
        EmptyGroup
    }

    [Header("Scare Mode Setup")]
    [SerializeField] private ScareType scareType = ScareType.AudioOnly;
    [SerializeField] private float displayDuration = 0.5f;

    [Header("Audio Settings")]
    [SerializeField] private AudioSource scareSound;

    [Header("UI Image Mode")]
    [SerializeField] private RawImage scareImage;

    [Header("3D Object Mode")]
    [SerializeField] private GameObject scareObject;

    [Header("Empty Group Mode")]
    [Tooltip("Kéo Empty GameObject (đã tắt sẵn) chứa toàn bộ quái/hiệu ứng vào đây.")]
    [SerializeField] private GameObject emptyGroup;

    private bool hasTriggered = false;

    private void OnTriggerEnter(Collider collision)
    {
        if (collision.CompareTag("Player") && !hasTriggered)
        {
            hasTriggered = true;
            TriggerJumpScare();
        }
    }
    public void TriggerJumpScare()
    {
        StartCoroutine(JumpScareSequence());
    }

    private IEnumerator JumpScareSequence()
    {
        // 1. Bật đối tượng tương ứng theo tùy chọn
        switch (scareType)
        {
            case ScareType.UIImage:
                if (scareImage != null) scareImage.gameObject.SetActive(true);
                break;

            case ScareType.Object3D:
                if (scareObject != null) scareObject.SetActive(true);
                break;

            case ScareType.EmptyGroup:
                if (emptyGroup != null) emptyGroup.SetActive(true);
                break;

            case ScareType.AudioOnly:
            default:
                break;
        }

        // 2. Phát âm thanh
        if (scareSound != null)
        {
            scareSound.Play();
        }

        // 3. Giữ trong khoảng thời gian
        yield return new WaitForSeconds(displayDuration);

        // 4. Tắt đối tượng sau khi kết thúc hù dọa
        switch (scareType)
        {
            case ScareType.UIImage:
                if (scareImage != null) scareImage.gameObject.SetActive(false);
                break;

            case ScareType.Object3D:
                if (scareObject != null) scareObject.SetActive(false);
                break;

            case ScareType.EmptyGroup:
                if (emptyGroup != null) emptyGroup.SetActive(false);
                break;
        }
    }
}