import gradio as gr
from PIL import Image
import os
import argparse
import random
import spaces


from OmniGen import OmniGenPipeline

pipe = OmniGenPipeline.from_pretrained(
    "Shitao/OmniGen-v1"
)

@spaces.GPU(duration=180)
def generate_image(text, img1, img2, img3, height, width, guidance_scale, img_guidance_scale, inference_steps, seed, separate_cfg_infer, offload_model,
            use_input_image_size_as_output, max_input_image_size, randomize_seed, save_images):
    input_images = [img1, img2, img3]
    # Delete None
    input_images = [img for img in input_images if img is not None]
    if len(input_images) == 0:
        input_images = None
    
    if randomize_seed:
        seed = random.randint(0, 10000000)

    output = pipe(
        prompt=text,
        input_images=input_images,
        height=height,
        width=width,
        guidance_scale=guidance_scale,
        img_guidance_scale=img_guidance_scale,
        num_inference_steps=inference_steps,
        separate_cfg_infer=separate_cfg_infer, 
        use_kv_cache=True,
        offload_kv_cache=True,
        offload_model=offload_model,
        use_input_image_size_as_output=use_input_image_size_as_output,
        seed=seed,
        max_input_image_size=max_input_image_size,
    )
    img = output[0]
    
    if save_images:
        # Save All Generated Images
        from datetime import datetime
        # Create outputs directory if it doesn't exist
        os.makedirs('outputs', exist_ok=True)
        # Generate unique filename with timestamp
        timestamp = datetime.now().strftime("%Y_%m_%d-%H_%M_%S")
        output_path = os.path.join('outputs', f'{timestamp}.png')
        # Save the image
        img.save(output_path)
    
    return img

def get_example():
    case = [
        [
            "卷发男子穿着红色衬衫在喝茶。",
            None,
            None,
            None,
            1024,
            1024,
            2.5,
            1.6,
            0,
            1024,
            False,
            False,
        ],
        [
            "<img><|image_1|></img>中的女子在人群中开心地挥手",
            "./imgs/test_cases/zhang.png",
            None,
            None,
            1024,
            1024,
            2.5,
            1.9,
            128,
            1024,
            False,
            False,
        ],
        [
            "一个穿黑衬衫的男子在读书。这个男子是<img><|image_1|></img>中右边的男子。",
            "./imgs/test_cases/two_man.jpg",
            None,
            None,
            1024,
            1024,
            2.5,
            1.6,
            0,
            1024,
            False,
            False,
        ],
        [
            "两个女子在酒吧里举着炸鸡腿。一个女子是<img><|image_1|></img>。另一个女子是<img><|image_2|></img>。",
            "./imgs/test_cases/mckenna.jpg",
            "./imgs/test_cases/Amanda.jpg",
            None,
            1024,
            1024,
            2.5,
            1.8,
            65,
            1024,
            False,
            False,
        ],
        [
            "一个男子和一个面部有皱纹的短发女子站在图书馆的书架前。这个男子是<img><|image_1|></img>中间的男子，这个女子是<img><|image_2|></img>中最年长的女子",
            "./imgs/test_cases/1.jpg",
            "./imgs/test_cases/2.jpg",
            None,
            1024,
            1024,
            2.5,
            1.6,
            60,
            1024,
            False,
            False,
        ],
        [
            "一男一女坐在教室的课桌前。这个男子是<img><|image_1|></img>中金发的男子。这个女子是<img><|image_2|></img>左边的女子",
            "./imgs/test_cases/3.jpg",
            "./imgs/test_cases/4.jpg",
            None,
            1024,
            1024,
            2.5,
            1.8,
            66,
            1024,
            False,
            False,
        ],
        [
            "<img><|image_1|></img>中的花被放在客厅木桌上<img><|image_2|></img>中间的花瓶里",
            "./imgs/test_cases/rose.jpg",
            "./imgs/test_cases/vase.jpg",
            None,
            1024,
            1024,
            2.5,
            1.6,
            66,
            1024,
            False,
            False,
        ],
        [
            "<img><|image_1|><img>\n移除女子的耳环。将杯子替换为装满冒泡冰可乐的透明玻璃杯。",
            "./imgs/demo_cases/t2i_woman_with_book.png",
            None,
            None,
            None,
            None,
            2.5,
            1.6,
            222,
            1024,
            False,
            True,
        ],
        [
            "检测这张图片中的人体骨架：<img><|image_1|></img>。",
            "./imgs/test_cases/control.jpg",
            None,
            None,
            1024,
            1024,
            2.0,
            1.6,
            0,
            1024,
            False,
            True,
        ],
        [
            "使用以下图片和文字作为条件生成新照片：<img><|image_1|><img>\n一个年轻男孩坐在图书馆的沙发上，手里拿着一本书。他的头发梳理整齐，嘴角带着淡淡的微笑，脸颊上散布着几颗雀斑。图书馆很安静，他身后是一排排装满书的书架。",
            "./imgs/demo_cases/skeletal.png",
            None,
            None,
            1024,
            1024,
            2,
            1.6,
            999,
            1024,
            False,
            True,
        ],
        [
            "按照这张图片<img><|image_1|><img>的姿势生成新照片：一个年轻男孩坐在图书馆的沙发上，手里拿着一本书。他的头发梳理整齐，嘴角带着淡淡的微笑，脸颊上散布着几颗雀斑。图书馆很安静，他身后是一排排装满书的书架。",
            "./imgs/demo_cases/edit.png",
            None,
            None,
            1024,
            1024,
            2.0,
            1.6,
            123,
            1024,
            False,
            True,
        ],
        [
            "按照这张图片<img><|image_1|><img>的深度映射生成新照片：一个年轻女孩坐在图书馆的沙发上，手里拿着一本书。她的头发梳理整齐，嘴角带着淡淡的微笑，脸颊上散布着几颗雀斑。图书馆很安静，她身后是一排排装满书的书架。",
            "./imgs/demo_cases/edit.png",
            None,
            None,
            1024,
            1024,
            2.0,
            1.6,
            1,
            1024,
            False,
            True,
        ],
        [
            "<img><|image_1|><\/img> 什么物品可以用来查看当前时间？请用蓝色高亮显示。",
            "./imgs/test_cases/watch.jpg",
            None,
            None,
            1024,
            1024,
            2.5,
            1.6,
            666,
            1024,
            False,
            True,
        ],
        [
            "根据以下示例，为输入生成输出。\n输入：<img><|image_1|></img>\n输出：<img><|image_2|></img>\n\n输入：<img><|image_3|></img>\n输出：",
            "./imgs/test_cases/icl1.jpg",
            "./imgs/test_cases/icl2.jpg",
            "./imgs/test_cases/icl3.jpg",
            224,
            224,
            2.5,
            1.6,
            1,
            768,
            False,
            False,
        ],
    ]
    return case

def run_for_examples(text, img1, img2, img3, height, width, guidance_scale, img_guidance_scale, seed, max_input_image_size, randomize_seed, use_input_image_size_as_output, save_images):    
    # 在函数内部设置默认值
    inference_steps = 50
    separate_cfg_infer = True
    offload_model = False
    
    return generate_image(
        text, img1, img2, img3, height, width, guidance_scale, img_guidance_scale, 
        inference_steps, seed, separate_cfg_infer, offload_model,
        use_input_image_size_as_output, max_input_image_size, randomize_seed, save_images
    )

description = """
OmniGen是一个统一的图像生成模型，您可以用它来执行各种任务，包括但不限于文本到图像生成、主题驱动生成、身份保持生成和图像条件生成。

对于多模态到图像生成，您需要传入一个字符串作为`prompt`，以及一个图像路径列表作为`input_images`。提示中的占位符应采用`<img><|image_*|></img>`格式（对于第一张图像，占位符是<img><|image_1|></img>；对于第二张图像，占位符是<img><|image_2|></img>）。

例如，使用一张女性图像来生成新图像：
prompt = "一个女人手持花束面对相机。这个女人是\<img\>\<|image_1|\>\</img\>。"

提示：
- 对于图像编辑任务和controlnet任务，我们建议将输出图像的高度和宽度设置为与输入图像相同。例如，如果您想编辑一张512x512的图像，您应该将输出图像的高度和宽度设置为512x512。您也可以设置`use_input_image_size_as_output`来自动将输出图像的高度和宽度设置为与输入图像相同。
- 对于内存不足或时间成本问题，您可以设置`offload_model=True`或参考[./docs/inference.md#requiremented-resources](https://github.com/VectorSpaceLab/OmniGen/blob/main/docs/inference.md#requiremented-resources)选择合适的设置。
- 如果输入多张图像时推理时间过长，请尝试减小`max_input_image_size`。更多详情请参考[./docs/inference.md#requiremented-resources](https://github.com/VectorSpaceLab/OmniGen/blob/main/docs/inference.md#requiremented-resources)。
- 过饱和：如果图像看起来过饱和，请降低`guidance_scale`。
- 不符合提示：如果图像不符合提示，请尝试增加`guidance_scale`。
- 低质量：更详细的提示将带来更好的结果。
- 动画风格：如果您希望生成的图像看起来不那么动画化，更真实，可以尝试在提示中添加"照片"。
- 编辑生成的图像：如果您用OmniGen生成了一张图像，然后想要编辑它，您不能使用相同的seed来编辑这张图像。例如，使用seed=0生成图像，然后使用seed=1编辑这张图像。
- 图像编辑：在您的提示中，我们建议将图像放在编辑指令之前。例如，使用`<img><|image_1|></img> 移除西装`，而不是`移除西装 <img><|image_1|></img>`。

由于配额限制，HF Spaces经常会遇到错误，所以建议在本地运行。
"""

article = """
---
**Citation** 
<br> 
If you find this repository useful, please consider giving a star ⭐ and a citation
```
@article{xiao2024omnigen,
  title={Omnigen: Unified image generation},
  author={Xiao, Shitao and Wang, Yueze and Zhou, Junjie and Yuan, Huaying and Xing, Xingrun and Yan, Ruiran and Wang, Shuting and Huang, Tiejun and Liu, Zheng},
  journal={arXiv preprint arXiv:2409.11340},
  year={2024}
}
```
**Contact**
<br>
If you have any questions, please feel free to open an issue or directly reach us out via email.
"""


# Gradio 
with gr.Blocks() as demo:
    gr.Markdown("# OmniGen: 统一图像生成模型 [论文](https://arxiv.org/abs/2409.11340) [代码](https://github.com/VectorSpaceLab/OmniGen)")
    gr.Markdown(description)
    with gr.Row():
        with gr.Column():
            # 文本提示
            prompt_input = gr.Textbox(
                label="输入提示词,使用 <img><|image_i|></img> 来表示第i张输入图片", placeholder="在此输入提示词..."
            )

            with gr.Row(equal_height=True):
                # 输入图片
                image_input_1 = gr.Image(label="<img><|image_1|></img>", type="filepath")
                image_input_2 = gr.Image(label="<img><|image_2|></img>", type="filepath")
                image_input_3 = gr.Image(label="<img><|image_3|></img>", type="filepath")

            # 滑块
            height_input = gr.Slider(
                label="高度", minimum=128, maximum=2048, value=1024, step=16
            )
            width_input = gr.Slider(
                label="宽度", minimum=128, maximum=2048, value=1024, step=16
            )

            guidance_scale_input = gr.Slider(
                label="引导尺度", minimum=1.0, maximum=5.0, value=2.5, step=0.1
            )

            img_guidance_scale_input = gr.Slider(
                label="图像引导尺度", minimum=1.0, maximum=2.0, value=1.6, step=0.1
            )

            num_inference_steps = gr.Slider(
                label="推理步数", minimum=1, maximum=100, value=50, step=1
            )

            seed_input = gr.Slider(
                label="随机种子", minimum=0, maximum=2147483647, value=42, step=1
            )
            randomize_seed = gr.Checkbox(label="随机化种子", value=True)

            max_input_image_size = gr.Slider(
                label="最大输入图像尺寸", minimum=128, maximum=2048, value=1024, step=16
            )

            separate_cfg_infer = gr.Checkbox(
                label="分离引导推理", info="是否为不同的引导使用单独的推理过程。这将减少内存消耗。", value=True,
            )
            offload_model = gr.Checkbox(
                label="模型卸载", info="将模型卸载到CPU，这将显著减少内存消耗但会降低生成速度。您可以取消分离引导推理并设置模型卸载=True。如果两者都为True，将进一步减少内存，但生成速度最慢", value=False,
            )
            use_input_image_size_as_output = gr.Checkbox(
                label="使用输入图像尺寸作为输出", info="自动调整输出图像尺寸与输入图像相同。对于编辑和controlnet任务，这可以确保输出图像与输入图像具有相同的尺寸，从而获得更好的性能", value=False,
            )

            # 生成按钮
            generate_button = gr.Button("生成图像")
            

        with gr.Column():
            with gr.Column():
                # 输出图像
                output_image = gr.Image(label="输出图像")
                save_images = gr.Checkbox(label="保存生成的图像", value=False)

    # 点击事件
    generate_button.click(
        generate_image,
        inputs=[
            prompt_input,
            image_input_1,
            image_input_2,
            image_input_3,
            height_input,
            width_input,
            guidance_scale_input,
            img_guidance_scale_input,
            num_inference_steps,
            seed_input,
            separate_cfg_infer,
            offload_model,
            use_input_image_size_as_output,
            max_input_image_size,
            randomize_seed,
            save_images,
        ],
        outputs=output_image,
    )

    gr.Examples(
        examples=get_example(),
        fn=run_for_examples,
        inputs=[
            prompt_input,
            image_input_1,
            image_input_2,
            image_input_3,
            height_input,
            width_input,
            guidance_scale_input,
            img_guidance_scale_input,
            seed_input,
            max_input_image_size,
            randomize_seed,
            use_input_image_size_as_output,
        ],
        outputs=output_image,
    )

    gr.Markdown(article)



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='运行 OmniGen')
    parser.add_argument('--share', action='store_true', help='分享 Gradio 应用')
    args = parser.parse_args()

    # 启动
    demo.launch(share=args.share)
