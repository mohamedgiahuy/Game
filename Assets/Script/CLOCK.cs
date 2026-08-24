using UnityEngine;
using TMPro;
using UnityEngine.UI;

public class GameClock : MonoBehaviour
{
    public Text clockText;

    public float gameMinutes = 60f; // Bắt đầu lúc 01:00
    public float realSecondsPerGameMinute = 1f;

    void Update()
    {
        gameMinutes += Time.deltaTime / realSecondsPerGameMinute;

        int hours = Mathf.FloorToInt(gameMinutes / 60f);
        int minutes = Mathf.FloorToInt(gameMinutes % 60f);

        // Đồng hồ 24 giờ
        hours %= 24;

        clockText.text = string.Format("{0:00}:{1:00}", hours, minutes);
    }
}