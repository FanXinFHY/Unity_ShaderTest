using UnityEngine;

/// <summary>
/// WASD 前后左右，长按空格上升，长按左Ctrl下降，按住Shift加速
/// </summary>
public class MovementController : MonoBehaviour
{
    [Header("速度设置")]
    [Tooltip("水平移动速度")]
    public float moveSpeed = 10f;

    [Tooltip("升降速度")]
    public float verticalSpeed = 6f;

    [Tooltip("按住Shift时的速度倍率")]
    public float fastMultiplier = 2.5f;

    [Tooltip("启停平滑度，0 表示无平滑，越大越跟手")]
    public float smoothing = 12f;

    [Header("视角旋转")]
    [Tooltip("鼠标灵敏度")]
    public float mouseSensitivity = 2.5f;

    [Tooltip("俯仰角下限（低头）")]
    public float minPitch = -89f;

    [Tooltip("俯仰角上限（抬头）")]
    public float maxPitch = 89f;

    private Vector3 _currentVelocity;
    private float _yaw;
    private float _pitch;

    void Start()
    {
        // 从当前朝向初始化，避免第一帧跳变
        Vector3 e = transform.eulerAngles;
        _yaw = e.y;
        _pitch = NormalizeAngle(e.x);

        // 启动即锁定光标，鼠标可直接旋转视角
        LockCursor(true);
    }

    void Update()
    {
        HandleCursorToggle();
        HandleRotation();
        HandleMovement();
    }

    // ---------------- 光标锁定/释放 ----------------
    void HandleCursorToggle()
    {
        // Esc 释放光标
        if (Input.GetKeyDown(KeyCode.Escape))
            LockCursor(false);

        // 光标未锁定时，点左键重新锁定
        if (Cursor.lockState != CursorLockMode.Locked && Input.GetMouseButtonDown(0))
            LockCursor(true);
    }

    void LockCursor(bool locked)
    {
        Cursor.lockState = locked ? CursorLockMode.Locked : CursorLockMode.None;
        Cursor.visible = !locked;
    }

    // ---------------- 视角旋转 ----------------
    void HandleRotation()
    {
        // 光标没锁定时不旋转，避免点 UI 时视角乱飞
        if (Cursor.lockState != CursorLockMode.Locked) return;

        float mx = Input.GetAxis("Mouse X") * mouseSensitivity;
        float my = Input.GetAxis("Mouse Y") * mouseSensitivity;

        _yaw += mx;
        _pitch -= my;                                   // 鼠标上移 → 抬头
        _pitch = Mathf.Clamp(_pitch, minPitch, maxPitch);

        // 累积 yaw/pitch 再合成，避免直接改 eulerAngles 造成抖动/滚转漂移
        transform.rotation = Quaternion.Euler(_pitch, _yaw, 0f);
    }

    // ---------------- 移动 ----------------
    void HandleMovement()
    {
        // 摄像机朝向投影到水平面，抬头低头时 W 也只走平面
        Vector3 forward = transform.forward;
        forward.y = 0f;
        forward.Normalize();

        Vector3 right = transform.right;
        right.y = 0f;
        right.Normalize();

        Vector3 inputDir = Vector3.zero;
        if (Input.GetKey(KeyCode.W)) inputDir += forward;
        if (Input.GetKey(KeyCode.S)) inputDir -= forward;
        if (Input.GetKey(KeyCode.D)) inputDir += right;
        if (Input.GetKey(KeyCode.A)) inputDir -= right;

        Vector3 targetVelocity = inputDir.normalized * moveSpeed;

        float vertical = 0f;
        if (Input.GetKey(KeyCode.Space)) vertical += 1f;
        if (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) vertical -= 1f;
        targetVelocity += Vector3.up * (vertical * verticalSpeed);

        if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))
            targetVelocity *= fastMultiplier;

        if (smoothing > 0f)
        {
            float t = 1f - Mathf.Exp(-smoothing * Time.deltaTime);
            _currentVelocity = Vector3.Lerp(_currentVelocity, targetVelocity, t);
        }
        else
        {
            _currentVelocity = targetVelocity;
        }

        transform.position += _currentVelocity * Time.deltaTime;
    }

    private static float NormalizeAngle(float angle)
    {
        angle %= 360f;
        if (angle > 180f) angle -= 360f;
        return angle;
    }
}