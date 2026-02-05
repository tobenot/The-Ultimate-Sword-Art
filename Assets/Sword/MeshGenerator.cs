using UnityEngine;
// 引入 Unity 编辑器专用的命名空间，这包含了操作资产的工具
#if UNITY_EDITOR
using UnityEditor;
#endif

// 这是一个编辑器工具脚本，它的唯一目的是在编辑器中生成一个网格资产。
[RequireComponent(typeof(MeshFilter))]
public class MeshGenerator : MonoBehaviour
{
    [Tooltip("数据纹理的宽度 (例如 128x128 纹理就填 128)")]
    public int textureWidth = 128;

    [Tooltip("数据纹理的高度 (例如 128x128 纹理就填 128)")]
    public int textureHeight = 128;

    // 我们把旧的功能升级了，现在它会一步到位
    [ContextMenu("Generate AND SAVE Blueprint Mesh")]
    void GenerateAndSaveMesh()
    {
        // --- 生成 Mesh 的逻辑 (与之前完全相同) ---
        int totalVertices = textureWidth * textureHeight;
        Mesh mesh = new Mesh();
        mesh.name = "Sword Blueprint Mesh";

        if (totalVertices > 65535) {
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        }

        Vector3[] vertices = new Vector3[totalVertices];
        Vector2[] uvs = new Vector2[totalVertices];
        int[] indices = new int[totalVertices];

        for (int y = 0; y < textureHeight; y++) {
            for (int x = 0; x < textureWidth; x++) {
                int index = x + y * textureWidth;
                vertices[index] = Vector3.zero;
                uvs[index] = new Vector2((x + 0.5f) / textureWidth, (y + 0.5f) / textureHeight);
                indices[index] = index;
            }
        }

        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.SetIndices(indices, MeshTopology.Points, 0);
        mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 1000f);

        // 将生成的 Mesh 临时赋给 MeshFilter，方便预览
        GetComponent<MeshFilter>().mesh = mesh;
        Debug.Log("成功在组件中生成蓝图网格，现在开始保存...");

        // --- 全新的核心：自动化保存资产 ---
        #if UNITY_EDITOR
        // 定义保存路径。 "Assets/" 是项目的根目录。
        string path = "Assets/Sword/GeneratedAssets/SwordBlueprintMesh.asset";

        // AssetDatabase 是 Unity 编辑器里管理所有资产的强大工具
        // CreateAsset 会将内存中的 mesh 对象写入到硬盘，成为一个 .asset 文件
        AssetDatabase.CreateAsset(mesh, path);
        // 保存所有更改
        AssetDatabase.SaveAssets();

        Debug.Log($"网格已成功保存到: {path}");
        EditorUtility.DisplayDialog("操作成功", $"网格已成功保存为资产！\n\n你可以在 'Assets/Sword/GeneratedAssets' 文件夹里找到它。", "太棒了！");
        #endif
    }
}