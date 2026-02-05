using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[RequireComponent(typeof(MeshFilter))]
public class MeshGenerator : MonoBehaviour
{
	public Mesh sourceSwordMesh;
	public int textureWidth = 32;
	public int textureHeight = 32;

	[ContextMenu("Generate AND SAVE Blueprint Mesh (Points)")]
	void GenerateAndSaveMesh()
	{
		int totalVertices = textureWidth * textureHeight;
		Mesh mesh = new Mesh();
		mesh.name = "Sword Blueprint Mesh";

		if (totalVertices > 65535)
		{
			mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
		}

		Vector3[] vertices = new Vector3[totalVertices];
		Vector2[] uvs = new Vector2[totalVertices];
		int[] indices = new int[totalVertices];

		for (int y = 0; y < textureHeight; y++)
		{
			for (int x = 0; x < textureWidth; x++)
			{
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

		GetComponent<MeshFilter>().mesh = mesh;
		Debug.Log("成功在组件中生成蓝图网格，现在开始保存...");

		#if UNITY_EDITOR
		string path = "Assets/Sword/GeneratedAssets/SwordBlueprintMesh.asset";
		AssetDatabase.CreateAsset(mesh, path);
		AssetDatabase.SaveAssets();

		Debug.Log($"网格已成功保存到: {path}");
		EditorUtility.DisplayDialog("操作成功", $"网格已成功保存为资产！\n\n你可以在 'Assets/Sword/GeneratedAssets' 文件夹里找到它。", "太棒了！");
		#endif
	}

	[ContextMenu("Generate Simple Cube Sword")]
	void GenerateSimpleCubeSword()
	{
		Mesh cubeMesh = new Mesh();
		cubeMesh.name = "Simple Cube Sword";

		Vector3[] vertices = new Vector3[]
		{
			new Vector3(-0.05f, -0.05f, 0f),
			new Vector3(0.05f, -0.05f, 0f),
			new Vector3(0.05f, 0.05f, 0f),
			new Vector3(-0.05f, 0.05f, 0f),
			new Vector3(-0.05f, -0.05f, 1f),
			new Vector3(0.05f, -0.05f, 1f),
			new Vector3(0.05f, 0.05f, 1f),
			new Vector3(-0.05f, 0.05f, 1f)
		};

		int[] triangles = new int[]
		{
			0, 2, 1, 0, 3, 2,
			4, 5, 6, 4, 6, 7,
			0, 1, 5, 0, 5, 4,
			1, 2, 6, 1, 6, 5,
			2, 3, 7, 2, 7, 6,
			3, 0, 4, 3, 4, 7
		};

		Vector2[] uvs = new Vector2[]
		{
			new Vector2(0, 0), new Vector2(1, 0), new Vector2(1, 1), new Vector2(0, 1),
			new Vector2(0, 0), new Vector2(1, 0), new Vector2(1, 1), new Vector2(0, 1)
		};

		cubeMesh.vertices = vertices;
		cubeMesh.triangles = triangles;
		cubeMesh.uv = uvs;
		cubeMesh.RecalculateNormals();
		cubeMesh.RecalculateBounds();

		#if UNITY_EDITOR
		string path = "Assets/Sword/GeneratedAssets/SimpleCubeSword.asset";
		AssetDatabase.CreateAsset(cubeMesh, path);
		AssetDatabase.SaveAssets();

		sourceSwordMesh = cubeMesh;
		Debug.Log($"简单立方体剑生成完毕并已自动设置到 sourceSwordMesh！路径: {path}");
		EditorUtility.DisplayDialog("操作成功", $"简单立方体剑已生成！\n\n已自动设置为 sourceSwordMesh\n现在可以执行 'Generate Mega Sword Mesh' 了\n\n路径: {path}", "太棒了！");
		#endif
	}

	[ContextMenu("Generate Mega Sword Mesh")]
	void GenerateMegaMesh()
	{
		if (sourceSwordMesh == null)
		{
			Debug.LogError("请先拖入剑模型到 sourceSwordMesh 字段，或者先执行 'Generate Simple Cube Sword'！");
			return;
		}

		int instanceCount = textureWidth * textureHeight;
		int vCount = sourceSwordMesh.vertexCount;
		int[] sourceIndices = sourceSwordMesh.GetIndices(0);
		int iCount = sourceIndices.Length;

		Mesh megaMesh = new Mesh();
		megaMesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
		megaMesh.name = "Mega Sword Mesh";

		Vector3[] vertices = new Vector3[instanceCount * vCount];
		Vector2[] uv0 = new Vector2[instanceCount * vCount];
		Vector2[] uv1 = new Vector2[instanceCount * vCount];
		Vector3[] normals = new Vector3[instanceCount * vCount];
		int[] indices = new int[instanceCount * iCount];

		for (int i = 0; i < instanceCount; i++)
		{
			float u = ((i % textureWidth) + 0.5f) / textureWidth;
			float v = ((i / textureWidth) + 0.5f) / textureHeight;

			for (int j = 0; j < vCount; j++)
			{
				int targetV = i * vCount + j;
				vertices[targetV] = sourceSwordMesh.vertices[j];
				normals[targetV] = sourceSwordMesh.normals[j];
				uv1[targetV] = sourceSwordMesh.uv[j];
				uv0[targetV] = new Vector2(u, v);
			}

			for (int j = 0; j < iCount; j++)
			{
				indices[i * iCount + j] = i * vCount + sourceIndices[j];
			}
		}

		megaMesh.vertices = vertices;
		megaMesh.normals = normals;
		megaMesh.uv = uv0;
		megaMesh.uv2 = uv1;
		megaMesh.SetIndices(indices, MeshTopology.Triangles, 0);
		megaMesh.bounds = new Bounds(Vector3.zero, Vector3.one * 1000f);

		#if UNITY_EDITOR
		string path = "Assets/Sword/GeneratedAssets/MegaSwordMesh.asset";
		AssetDatabase.CreateAsset(megaMesh, path);
		AssetDatabase.SaveAssets();

		GetComponent<MeshFilter>().mesh = megaMesh;
		Debug.Log($"万剑大网格生成完毕！总顶点: {vertices.Length}, 总三角形: {indices.Length / 3}");
		EditorUtility.DisplayDialog("操作成功", $"万剑大网格已生成！\n\n实例数: {instanceCount}\n单剑顶点: {vCount}\n总顶点: {vertices.Length}\n\n保存路径: {path}", "太棒了！");
		#endif
	}
}